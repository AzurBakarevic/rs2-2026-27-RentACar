using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using RentACar.Model.Constants;
using RentACar.Model.Exceptions;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class UserService
    : BaseCRUDService<User, UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
{
    // Koliko dugo se verzija tokena čuva u memoriji; svaka promjena je i ranije briše iz keša.
    private static readonly TimeSpan TokenVersionCacheDuration = TimeSpan.FromMinutes(5);

    private readonly ICryptoService _cryptoService;
    private readonly IAuthenticatedUserAccessor _authenticatedUser;
    private readonly IMemoryCache _cache;
    private readonly IValidator<UserLoginRequest> _loginValidator;
    private readonly IValidator<UserRegisterRequest> _registerValidator;
    private readonly IValidator<UserProfileUpdateRequest> _profileValidator;
    private readonly IValidator<UserPasswordChangeRequest> _passwordChangeValidator;
    private readonly IValidator<PasswordForgotRequest> _passwordForgotValidator;
    private readonly IValidator<PasswordResetRequest> _passwordResetValidator;
    private readonly PendingEmails _pendingEmails;

    public UserService(
        RentACarDbContext dbContext,
        IMapper mapper,
        IValidator<UserInsertRequest> insertValidator,
        IValidator<UserUpdateRequest> updateValidator,
        IValidator<UserLoginRequest> loginValidator,
        IValidator<UserRegisterRequest> registerValidator,
        IValidator<UserProfileUpdateRequest> profileValidator,
        IValidator<UserPasswordChangeRequest> passwordChangeValidator,
        IValidator<PasswordForgotRequest> passwordForgotValidator,
        IValidator<PasswordResetRequest> passwordResetValidator,
        ICryptoService cryptoService,
        IAuthenticatedUserAccessor authenticatedUser,
        IMemoryCache cache,
        PendingEmails pendingEmails) : base(dbContext, mapper, insertValidator, updateValidator)
    {
        _loginValidator = loginValidator;
        _registerValidator = registerValidator;
        _profileValidator = profileValidator;
        _passwordChangeValidator = passwordChangeValidator;
        _passwordForgotValidator = passwordForgotValidator;
        _passwordResetValidator = passwordResetValidator;
        _pendingEmails = pendingEmails;
        _cryptoService = cryptoService;
        _authenticatedUser = authenticatedUser;
        _cache = cache;
    }

    // Logički obrisani korisnici ne postoje ni za jednu operaciju (lista, detalji, izmjena, prijava).
    protected override IQueryable<User> GetQuery() => _dbContext.Users.Where(x => !x.IsDeleted);

    protected override IQueryable<User> ApplyFilters(IQueryable<User> query, UserSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Text))
        {
            query = query.Where(x => x.FirstName.Contains(search.Text)
                                     || x.LastName.Contains(search.Text)
                                     || x.Username.Contains(search.Text)
                                     || x.Email.Contains(search.Text));
        }

        if (search.RoleId.HasValue)
        {
            query = query.Where(x => x.RoleId == search.RoleId.Value);
        }

        if (search.IsActive.HasValue)
        {
            query = query.Where(x => x.IsActive == search.IsActive.Value);
        }

        return query;
    }

    protected override IQueryable<User> ApplyOrdering(IQueryable<User> query)
        => query.OrderBy(x => x.LastName).ThenBy(x => x.FirstName).ThenBy(x => x.Id);

    // ---------- Administracija korisnika (desktop) ----------

    protected override User MapInsertRequestToEntity(UserInsertRequest request)
    {
        var entity = base.MapInsertRequestToEntity(request);
        SetPassword(entity, request.Password);
        entity.CreatedAt = DateTime.UtcNow;
        return entity;
    }

    protected override async Task BeforeInsertAsync(UserInsertRequest request, User entity)
    {
        await EnsureRoleExistsAsync(entity.RoleId);
        await NormalizeAndEnsureUniqueAsync(entity);
    }

    protected override void MapUpdateRequestToEntity(UserUpdateRequest request, User entity)
    {
        base.MapUpdateRequestToEntity(request, entity);

        // Nova lozinka samo ako ju je administrator unio; stara se ne traži (upute 4).
        if (!string.IsNullOrEmpty(request.Password))
        {
            SetPassword(entity, request.Password);
        }
    }

    protected override async Task BeforeUpdateAsync(UserUpdateRequest request, User entity)
    {
        var entry = _dbContext.Entry(entity);
        var roleChanged = entry.Property(x => x.RoleId).OriginalValue != entity.RoleId;
        var activeChanged = entry.Property(x => x.IsActive).OriginalValue != entity.IsActive;

        // Administrator ne smije sam sebi zaključati pristup.
        if (entity.Id == _authenticatedUser.GetUserId())
        {
            if (roleChanged)
            {
                throw new ClientException("Ne možete promijeniti vlastitu ulogu.");
            }

            if (!entity.IsActive)
            {
                throw new ClientException("Ne možete deaktivirati vlastiti nalog.");
            }
        }

        if (roleChanged)
        {
            await EnsureRoleExistsAsync(entity.RoleId);
        }

        await NormalizeAndEnsureUniqueAsync(entity);

        // Uloga i status su u tokenu ili se provjeravaju uz njega: stari tokeni moraju prestati važiti.
        if (roleChanged || activeChanged || !string.IsNullOrEmpty(request.Password))
        {
            entity.TokenVersion++;
        }
    }

    public override async Task<UserResponse> UpdateAsync(int id, UserUpdateRequest request)
    {
        var result = await base.UpdateAsync(id, request);
        RemoveTokenVersionFromCache(id);
        return result;
    }

    // Logičko brisanje: zapis ostaje zbog rezervacija i plaćanja, a nalog se više ne može koristiti.
    public override async Task DeleteAsync(int id)
    {
        var entity = await GetQuery().FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new KeyNotFoundException($"User with id {id} not found.");

        if (entity.Id == _authenticatedUser.GetUserId())
        {
            throw new ClientException("Ne možete obrisati vlastiti nalog.");
        }

        entity.IsDeleted = true;
        entity.IsActive = false;
        entity.TokenVersion++;

        await _dbContext.SaveChangesAsync();
        RemoveTokenVersionFromCache(id);
    }

    // ---------- Prijava, registracija, odjava ----------

    public async Task<AuthenticatedUser> AuthenticateAsync(UserLoginRequest request)
    {
        await _loginValidator.ValidateAndThrowAsync(request);

        var user = await GetQuery()
            .Include(x => x.Role)
            .FirstOrDefaultAsync(x => x.Username == request.Username);

        // Ista poruka za nepostojeće korisničko ime i pogrešnu lozinku, da se ne otkriva koji nalozi postoje.
        if (user == null || !_cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password))
        {
            throw new ClientException("Pogrešno korisničko ime ili lozinka.");
        }

        if (!user.IsActive)
        {
            throw new ClientException("Vaš nalog je deaktiviran. Obratite se administratoru.");
        }

        return new AuthenticatedUser(user.Id, user.Username, user.Role.Name, user.TokenVersion);
    }

    public async Task<UserResponse> RegisterAsync(UserRegisterRequest request)
    {
        await _registerValidator.ValidateAndThrowAsync(request);

        var entity = _mapper.Map<User>(request);

        // Uloga se nikad ne uzima od klijenta (upute 5).
        entity.RoleId = await _dbContext.Roles
            .Where(x => x.Name == RoleNames.Customer)
            .Select(x => x.Id)
            .FirstAsync();
        entity.IsActive = true;
        entity.CreatedAt = DateTime.UtcNow;
        SetPassword(entity, request.Password);

        await NormalizeAndEnsureUniqueAsync(entity);

        _dbContext.Users.Add(entity);
        await _dbContext.SaveChangesAsync();

        return await GetByIdAsync(entity.Id);
    }

    // Odjava poništava token na serveru (upute 5): nova verzija znači da stari tokeni više ne prolaze.
    public async Task LogoutAsync()
    {
        var entity = await GetCurrentUserAsync();
        entity.TokenVersion++;

        await _dbContext.SaveChangesAsync();
        RemoveTokenVersionFromCache(entity.Id);
    }

    // Poziva se na svakom zahtjevu s tokenom, pa se rezultat kešira (upute 8.2).
    public async Task<bool> IsTokenValidAsync(int userId, int tokenVersion)
    {
        var currentVersion = await _cache.GetOrCreateAsync(TokenVersionCacheKey(userId), entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TokenVersionCacheDuration;

            // null = korisnik ne postoji, obrisan je ili deaktiviran: nijedan njegov token ne važi.
            return _dbContext.Users
                .AsNoTracking()
                .Where(x => x.Id == userId && !x.IsDeleted && x.IsActive)
                .Select(x => (int?)x.TokenVersion)
                .FirstOrDefaultAsync();
        });

        return currentVersion == tokenVersion;
    }

    // ---------- Vlastiti profil (Id iz tokena) ----------

    public Task<UserResponse> GetProfileAsync()
    {
        return GetByIdAsync(GetCurrentUserId());
    }

    public async Task<UserResponse> UpdateProfileAsync(UserProfileUpdateRequest request)
    {
        await _profileValidator.ValidateAndThrowAsync(request);

        var entity = await GetCurrentUserAsync();
        _mapper.Map(request, entity);

        await NormalizeAndEnsureUniqueAsync(entity);
        await _dbContext.SaveChangesAsync();

        return await GetByIdAsync(entity.Id);
    }

    // Korisnik mora potvrditi staru lozinku (upute 4). Nakon promjene se mora ponovo prijaviti.
    public async Task ChangePasswordAsync(UserPasswordChangeRequest request)
    {
        await _passwordChangeValidator.ValidateAndThrowAsync(request);

        var entity = await GetCurrentUserAsync();

        if (!_cryptoService.Verify(entity.PasswordHash, entity.PasswordSalt, request.OldPassword))
        {
            throw new ClientException("Trenutna lozinka nije ispravna.");
        }

        SetPassword(entity, request.NewPassword);
        entity.TokenVersion++;

        await _dbContext.SaveChangesAsync();
        RemoveTokenVersionFromCache(entity.Id);
    }

    // ---------- Reset zaboravljene lozinke (prijava) ----------

    // Šalje kod na e-mail. Odgovor je uvijek isti, bez obzira postoji li nalog s tom adresom,
    // da se preko ovog endpointa ne može saznati ko je registrovan.
    public async Task RequestPasswordResetAsync(PasswordForgotRequest request)
    {
        await _passwordForgotValidator.ValidateAndThrowAsync(request);

        // Kod i hash se prave i kad nalog ne postoji: hashiranje traje, pa bi brži odgovor otkrio nepostojeći e-mail.
        var code = PasswordResetRules.GenerateCode();
        var salt = _cryptoService.GenerateSalt();
        var hash = _cryptoService.GenerateHash(code, salt);

        var userId = await FindActiveUserIdByEmailAsync(request.Email);
        if (userId == null)
        {
            return;
        }

        await using var transaction = await _dbContext.Database.BeginTransactionAsync();
        await LockUserAsync(userId.Value);

        // Vrijeme tek nakon zaključavanja: zahtjev koji je čekao vidi promjene prethodnog.
        var now = DateTime.UtcNow;

        var lastCodeCreatedAt = await _dbContext.PasswordResetCodes
            .Where(x => x.UserId == userId)
            .MaxAsync(x => (DateTime?)x.CreatedAt);

        if (lastCodeCreatedAt > now.AddSeconds(-PasswordResetRules.ResendCooldownSeconds))
        {
            return;
        }

        // Važi samo najnoviji kod.
        await _dbContext.PasswordResetCodes
            .Where(x => x.UserId == userId && x.UsedAt == null && x.ExpiresAt > now)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.ExpiresAt, now));

        _dbContext.PasswordResetCodes.Add(new PasswordResetCode
        {
            UserId = userId.Value,
            CodeHash = hash,
            CodeSalt = salt,
            CreatedAt = now,
            ExpiresAt = now.AddMinutes(PasswordResetRules.CodeValidMinutes)
        });

        var recipient = await GetQuery()
            .Where(x => x.Id == userId)
            .Select(x => new { x.Email, x.FirstName })
            .FirstAsync();

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();

        _pendingEmails.Add(EmailMessages.PasswordResetCode(recipient.Email, recipient.FirstName, code));
        await _pendingEmails.PublishAsync();
    }

    // Postavlja novu lozinku uz kod iz e-maila. Ista poruka za nepostojeći e-mail, pogrešan, istekao i iskorišten kod.
    public async Task ResetPasswordAsync(PasswordResetRequest request)
    {
        await _passwordResetValidator.ValidateAndThrowAsync(request);

        var userId = await FindActiveUserIdByEmailAsync(request.Email)
            ?? throw new ClientException(PasswordResetRules.InvalidCodeMessage);

        await using var transaction = await _dbContext.Database.BeginTransactionAsync();
        await LockUserAsync(userId);

        var now = DateTime.UtcNow;

        // Kod važi dok nije iskorišten, nije istekao i ima manje od 5 pogrešnih unosa, pa se ne može pogoditi isprobavanjem.
        var resetCode = await _dbContext.PasswordResetCodes
            .Where(x => x.UserId == userId
                        && x.UsedAt == null
                        && x.ExpiresAt > now
                        && x.FailedAttempts < PasswordResetRules.MaxFailedAttempts)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync()
            ?? throw new ClientException(PasswordResetRules.InvalidCodeMessage);

        if (!_cryptoService.Verify(resetCode.CodeHash, resetCode.CodeSalt, request.Code))
        {
            resetCode.FailedAttempts++;
            await _dbContext.SaveChangesAsync();
            await transaction.CommitAsync();

            throw new ClientException(PasswordResetRules.InvalidCodeMessage);
        }

        var user = await GetQuery().FirstAsync(x => x.Id == userId);

        resetCode.UsedAt = now;
        SetPassword(user, request.NewPassword);

        // Kao pri promjeni lozinke: sve postojeće prijave prestaju važiti.
        user.TokenVersion++;

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();

        RemoveTokenVersionFromCache(userId);
    }

    // ---------- Pomoćne metode ----------

    // Deaktiviran i obrisan nalog ne može resetovati lozinku (prijava mu ionako nije dozvoljena).
    private Task<int?> FindActiveUserIdByEmailAsync(string email)
    {
        var trimmed = email.Trim();

        return GetQuery()
            .Where(x => x.Email == trimmed && x.IsActive)
            .Select(x => (int?)x.Id)
            .FirstOrDefaultAsync();
    }

    // Zahtjevi za reset istog naloga idu jedan za drugim (UPDLOCK do kraja transakcije), pa se ni rok za novi kod
    // ni broj pogrešnih pokušaja ne mogu zaobići istovremenim zahtjevima.
    private Task LockUserAsync(int userId)
        => _dbContext.Database.ExecuteSqlAsync($"SELECT Id FROM Users WITH (UPDLOCK, ROWLOCK) WHERE Id = {userId}");

    private int GetCurrentUserId()
    {
        return _authenticatedUser.GetUserId()
            ?? throw new UnauthorizedAccessException("No authenticated user in the current request.");
    }

    private async Task<User> GetCurrentUserAsync()
    {
        var id = GetCurrentUserId();
        return await GetQuery().FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new KeyNotFoundException($"User with id {id} not found.");
    }

    private void SetPassword(User entity, string password)
    {
        entity.PasswordSalt = _cryptoService.GenerateSalt();
        entity.PasswordHash = _cryptoService.GenerateHash(password, entity.PasswordSalt);
    }

    private async Task EnsureRoleExistsAsync(int roleId)
    {
        if (!await _dbContext.Roles.AnyAsync(x => x.Id == roleId))
        {
            throw new ClientException("Odabrana uloga ne postoji.");
        }
    }

    // E-mail i korisničko ime moraju biti jedinstveni među neobrisanim korisnicima (kao filtrirani unique indeksi).
    private async Task NormalizeAndEnsureUniqueAsync(User entity)
    {
        entity.FirstName = entity.FirstName.Trim();
        entity.LastName = entity.LastName.Trim();
        entity.Email = entity.Email.Trim();
        entity.PhoneNumber = entity.PhoneNumber.Trim();
        entity.Username = entity.Username.Trim();
        entity.DriverLicenseNumber = string.IsNullOrWhiteSpace(entity.DriverLicenseNumber)
            ? null
            : entity.DriverLicenseNumber.Trim();

        if (await GetQuery().AnyAsync(x => x.Email == entity.Email && x.Id != entity.Id))
        {
            throw new ClientException("E-mail adresa je već zauzeta.");
        }

        if (await GetQuery().AnyAsync(x => x.Username == entity.Username && x.Id != entity.Id))
        {
            throw new ClientException("Korisničko ime je već zauzeto.");
        }
    }

    private static string TokenVersionCacheKey(int userId) => $"user-token-version:{userId}";

    private void RemoveTokenVersionFromCache(int userId) => _cache.Remove(TokenVersionCacheKey(userId));
}
