/// Modelo de datos para una seña de Lengua de Señas.
class SignModel {
  /// Identificador único de la seña.
  final String id;

  /// Texto o concepto que representa la seña (ej. "Hola", "Comida").
  final String palabra;

  /// Categoría a la que pertenece la seña (ej. "Saludos", "Alimentos").
  final String categoria;

  /// Ruta del asset de imagen dentro del proyecto Flutter.
  final String pathImagen;

  /// Color de acento asociado a la categoría (para uso visual en UI).
  final int colorCategoria;

  /// Ícono representativo de la categoría (código de MaterialIcons).
  final int iconoCategoria;

  const SignModel({
    required this.id,
    required this.palabra,
    required this.categoria,
    required this.pathImagen,
    required this.colorCategoria,
    required this.iconoCategoria,
  });
}
