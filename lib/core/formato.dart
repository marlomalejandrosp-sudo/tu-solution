/// Funciones para mostrar datos de forma uniforme en toda la app.
/// No usan `intl`, así no dependen de inicializar ningún idioma.
abstract final class Formato {
  static const _diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
    'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  static String _dos(int n) => n.toString().padLeft(2, '0');

  /// Dinero en pesos enteros, con separador de miles: "$ 12 500".
  static String dinero(int valor) {
    final negativo = valor < 0;
    final digitos = valor.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      final restantes = digitos.length - i;
      buffer.write(digitos[i]);
      if (restantes > 1 && restantes % 3 == 1) buffer.write(' ');
    }
    return '${negativo ? '-' : ''}\$ $buffer';
  }

  /// Kilometraje: "245 000 km".
  static String km(int valor) {
    final digitos = valor.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      final restantes = digitos.length - i;
      buffer.write(digitos[i]);
      if (restantes > 1 && restantes % 3 == 1) buffer.write(' ');
    }
    return '$buffer km';
  }

  /// "52345678" -> "5234 5678"
  static String telefono(String t) {
    if (t.length != 8) return t;
    return '${t.substring(0, 4)} ${t.substring(4)}';
  }

  /// "09:30"
  static String hora(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';

  /// "21/10/2026"
  static String fecha(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}/${d.year}';

  /// "21/10/2026 09:30"
  static String fechaHora(DateTime d) => '${fecha(d)} ${hora(d)}';

  /// "mié 21 de octubre"
  static String fechaLarga(DateTime d) =>
      '${_diasCortos[d.weekday - 1].toLowerCase()} ${d.day} de '
      '${_meses[d.month - 1]}';

  /// "21 oct"
  static String diaMesCorto(DateTime d) =>
      '${d.day} ${_meses[d.month - 1].substring(0, 3)}';

  /// "1 orden" / "3 órdenes"
  static String plural(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';
}
