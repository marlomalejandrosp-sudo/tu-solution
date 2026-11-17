/// Validaciones de los datos que se escriben en los formularios.
/// Cada función devuelve el mensaje de error, o null si el valor es válido.
/// Están aquí (y no en las pantallas) para que las reglas vivan en un solo
/// lugar y las usen tanto los formularios como el ViewModel.
abstract final class Validadores {
  static String? nombre(String? v, {String campo = 'El nombre'}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return '$campo es obligatorio';
    if (t.length < 3) return '$campo debe tener al menos 3 letras';
    if (t.length > 60) return '$campo no puede pasar de 60 caracteres';
    return null;
  }

  /// Teléfono de 8 dígitos (formato cubano).
  static String? telefono(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El teléfono es obligatorio';
    if (!RegExp(r'^\d{8}$').hasMatch(t)) {
      return 'El teléfono debe tener 8 dígitos';
    }
    return null;
  }

  static String? textoObligatorio(String? v, String campo, {int max = 40}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return '$campo es obligatorio';
    if (t.length > max) return '$campo no puede pasar de $max caracteres';
    return null;
  }

  /// El número de serie se guarda en mayúsculas y sin espacios ni guiones,
  /// para que "sn-12 ab" y "SN12AB" sean el mismo.
  static String normalizarSerie(String v) =>
      v.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

  static String? serie(String? v) {
    final t = normalizarSerie(v ?? '');
    if (t.isEmpty) return 'El número de serie es obligatorio';
    if (!RegExp(r'^[A-Z0-9]{4,20}$').hasMatch(t)) {
      return 'Serie no válida (4 a 20 letras o números)';
    }
    return null;
  }

  /// Dinero en pesos enteros mayor que cero.
  static String? dineroPositivo(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Escribe un monto';
    if (n <= 0) return 'Debe ser mayor que cero';
    return null;
  }

  static String? enteroNoNegativo(String? v, String campo) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Escribe $campo';
    if (n < 0) return '$campo no puede ser negativo';
    return null;
  }

  static String? cantidadPositiva(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Escribe la cantidad';
    if (n <= 0) return 'Debe ser mayor que cero';
    return null;
  }

  static String? codigo(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El código es obligatorio';
    if (t.length > 20) return 'El código es demasiado largo';
    return null;
  }

  static String? falla(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Describe la falla que reporta el cliente';
    if (t.length < 5) return 'Describe la falla con un poco más de detalle';
    if (t.length > 300) return 'Máximo 300 caracteres';
    return null;
  }
}
