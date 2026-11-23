using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
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
    private const string LastAdministratorMessage = "U sistemu mora ostati bar jedan aktivni administrator.";

    private readonly ICryptoService _cryptoService;
    private readonly IAuthenticatedUserAccessor _authenticatedUser;
    private readonly IValidator<UserLoginRequest> _loginValidator;
    private readonly IValidator<UserRegisterRequest> _registerValidator;
    private readonly IValidator<UserProfileUpdateRequest> _profileValidator;
    private readonly IValidator<UserPasswordChangeRequest> _passwordChangeValidator;
    private readonly IValidator<PasswordForgotRequest> _passwordForgotValidator;
    private readonly IValidator<PasswordResetRequest> _passwordResetValidator;
    private readonly IValidator<ImageUploadRequest> _imageValidator;
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
        IValidator<ImageUploadRequest> imageValidator,
        ICryptoService cryptoService,
        IAuthenticatedUserAccessor authenticatedUser,
        PendingEmails pendingEmails) : base(dbContext, mapper, insertValidator, updateValidator)
    {
        _loginValidator = loginValidator;
        _registerValidator = registerValidator;
        _profileValidator = profileValidator;
        _passwordChangeValidator = passwordChangeValidator;
        _passwordForgotValidator = passwordForgotValidator;
        _passwordResetValidator = passwordResetValidator;
        _imageValidator = imageValidator;
        _pendingEmails = pendingEmails;
        _cryptoService = cryptoService;
        _authenticatedUser = authenticatedUser;
    }

    protected override IQueryable<User> GetQuery() => _dbContext.Users.Where(x => !x.IsDeleted);

    protected override IQueryable<User> ApplyFilters(IQueryable<User> query, UserSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Text))
        {
            var text = search.Text.Trim();
            query = query.Where(x => (x.FirstName + " " + x.LastName).Contains(text)
                                     || x.Username.Contains(text)
                                     || x.Email.Contains(text));
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

    public override async Task<PageResult<UserResponse>> GetAllAsync(UserSearchObject? search = null)
    {
        var result = await base.GetAllAsync(search);

        foreach (var item in result.Items)
        {
            SetComputedFields(item);
        }

        return result;
    }

    public override async Task<UserResponse> GetByIdAsync(int id)
    {
        var user = await base.GetByIdAsync(id);
        SetComputedFields(user);
        return user;
    }

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

        if (!string.IsNullOrEmpty(request.Password))
        {
            SetPassword(entity, request.Password);
        }
    }

    protected override async Task BeforeUpdateAsync(UserUpdateRequest request, User entity)
    {
        var entry = _dbContext.Entry(entity);
        var originalRoleId = entry.Property(x => x.RoleId).OriginalValue;
        var originalIsActive = entry.Property(x => x.IsActive).OriginalValue;
        var roleChanged = originalRoleId != entity.RoleId;
        var activeChanged = originalIsActive != entity.IsActive;

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

        if (roleChanged || activeChanged)
        {
            var administratorRoleId = await GetAdministratorRoleIdAsync();
            var wasActiveAdministrator = originalIsActive && originalRoleId == administratorRoleId;
            var isActiveAdministrator = entity.IsActive && entity.RoleId == administratorRoleId;

            if (wasActiveAdministrator && !isActiveAdministrator)
            {
                await EnsureAnotherActiveAdministratorAsync(entity.Id);
            }
        }

        await NormalizeAndEnsureUniqueAsync(entity);

        if (roleChanged || activeChanged || !string.IsNullOrEmpty(request.Password))
        {
            entity.TokenVersion++;
        }
    }

    public override async Task<UserResponse> UpdateAsync(int id, UserUpdateRequest request)
    {
        await using var transaction = await _dbContext.Database.BeginTransactionAsync();
        await LockAdministratorRoleAsync();
        await LockUserAsync(id);

        var result = await base.UpdateAsync(id, request);
        await transaction.CommitAsync();

        return result;
    }

    public override async Task DeleteAsync(int id)
    {
        await using var transaction = await _dbContext.Database.BeginTransactionAsync();
        await LockAdministratorRoleAsync();
        await LockUserAsync(id);

        var entity = await GetQuery().FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new KeyNotFoundException($"User with id {id} not found.");

        if (entity.Id == _authenticatedUser.GetUserId())
        {
            throw new ClientException(DeleteBlockedReasons.OwnAccount);
        }

        if (await _dbContext.Reservations.AnyAsync(x => x.UserId == id && ReservationStatuses.Active.Contains(x.Status)))
        {
            throw new ClientException(DeleteBlockedReasons.UserHasActiveReservations);
        }

        if (entity.IsActive && entity.RoleId == await GetAdministratorRoleIdAsync())
        {
            await EnsureAnotherActiveAdministratorAsync(entity.Id);
        }

        entity.IsDeleted = true;
        entity.IsActive = false;
        entity.TokenVersion++;

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();
    }

    public async Task<ImageResponse> GetImageAsync(int id)
    {
        var image = await GetQuery()
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => x.ProfileImage)
            .FirstOrDefaultAsync();

        if (image == null || image.Length == 0)
        {
            throw new KeyNotFoundException($"Profile image for user with id {id} not found.");
        }

        return new ImageResponse
        {
            Content = image,
            ContentType = ImageFormat.DetectContentType(image) ?? "application/octet-stream"
        };
    }

    public async Task SetImageAsync(int id, ImageUploadRequest request)
    {
        await _imageValidator.ValidateAndThrowAsync(request);
        await UpdateImageAsync(id, request.Content);
    }

    public Task DeleteImageAsync(int id) => UpdateImageAsync(id, null);

    public async Task<AuthenticatedUser> AuthenticateAsync(UserLoginRequest request)
    {
        await _loginValidator.ValidateAndThrowAsync(request);

        var user = await GetQuery()
            .Include(x => x.Role)
            .FirstOrDefaultAsync(x => x.Username == request.Username);

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

    public async Task LogoutAsync()
    {
        var entity = await GetCurrentUserAsync();
        entity.TokenVersion++;

        await _dbContext.SaveChangesAsync();
    }

    public Task<bool> IsTokenValidAsync(int userId, int tokenVersion)
        => _dbContext.Users
            .AsNoTracking()
            .AnyAsync(x => x.Id == userId && !x.IsDeleted && x.IsActive && x.TokenVersion == tokenVersion);

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
    }

    public Task<ImageResponse> GetProfileImageAsync() => GetImageAsync(GetCurrentUserId());

    public Task SetProfileImageAsync(ImageUploadRequest request) => SetImageAsync(GetCurrentUserId(), request);

    public Task DeleteProfileImageAsync() => DeleteImageAsync(GetCurrentUserId());

    public async Task RequestPasswordResetAsync(PasswordForgotRequest request)
    {
        await _passwordForgotValidator.ValidateAndThrowAsync(request);

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

        var now = DateTime.UtcNow;

        var lastCodeCreatedAt = await _dbContext.PasswordResetCodes
            .Where(x => x.UserId == userId)
            .MaxAsync(x => (DateTime?)x.CreatedAt);

        if (lastCodeCreatedAt > now.AddSeconds(-PasswordResetRules.ResendCooldownSeconds))
        {
            return;
        }

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

    public async Task ResetPasswordAsync(PasswordResetRequest request)
    {
        await _passwordResetValidator.ValidateAndThrowAsync(request);

        var userId = await FindActiveUserIdByEmailAsync(request.Email)
            ?? throw new ClientException(PasswordResetRules.InvalidCodeMessage);

        await using var transaction = await _dbContext.Database.BeginTransactionAsync();
        await LockUserAsync(userId);

        var now = DateTime.UtcNow;

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

        user.TokenVersion++;

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();
    }

    private async Task UpdateImageAsync(int id, byte[]? image)
    {
        var updated = await GetQuery()
            .Where(x => x.Id == id)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.ProfileImage, image));

        if (updated == 0)
        {
            throw new KeyNotFoundException($"User with id {id} not found.");
        }
    }

    private Task<int?> FindActiveUserIdByEmailAsync(string email)
    {
        var trimmed = email.Trim();

        return GetQuery()
            .Where(x => x.Email == trimmed && x.IsActive)
            .Select(x => (int?)x.Id)
            .FirstOrDefaultAsync();
    }

    private Task LockUserAsync(int userId)
        => _dbContext.Database.ExecuteSqlAsync($"SELECT Id FROM Users WITH (UPDLOCK, ROWLOCK) WHERE Id = {userId}");

    private Task LockAdministratorRoleAsync()
        => _dbContext.Database.ExecuteSqlAsync(
            $"SELECT Id FROM Roles WITH (UPDLOCK, ROWLOCK) WHERE Name = {RoleNames.Administrator}");

    private Task<int> GetAdministratorRoleIdAsync()
        => _dbContext.Roles
            .Where(x => x.Name == RoleNames.Administrator)
            .Select(x => x.Id)
            .FirstAsync();

    private async Task EnsureAnotherActiveAdministratorAsync(int userId)
    {
        if (!await GetQuery().AnyAsync(x => x.Id != userId && x.IsActive && x.Role.Name == RoleNames.Administrator))
        {
            throw new ClientException(LastAdministratorMessage);
        }
    }

    private void SetComputedFields(UserResponse user)
    {
        user.DeleteBlockedReason = DeleteBlockedReasons.User(user.Id == _authenticatedUser.GetUserId(), user.ActiveReservationCount);
    }

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
}
