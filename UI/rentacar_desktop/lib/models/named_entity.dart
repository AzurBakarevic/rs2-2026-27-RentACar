/// Zapis šifarnika koji ima Id i naziv (marka, model, kategorija, gorivo, mjenjač).
abstract interface class NamedEntity {
  int get id;
  String get name;
}
