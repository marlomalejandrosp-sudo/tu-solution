import 'package:flutter/material.dart';

/// Muestra un aviso breve en la parte inferior de la pantalla, sustituyendo
/// el anterior si todavía estaba visible.
void mostrarAviso(
  BuildContext context,
  String texto, {
  String? accion,
  VoidCallback? alPulsarAccion,
}) {
  final mensajero = ScaffoldMessenger.of(context);
  mensajero.hideCurrentSnackBar();
  mensajero.showSnackBar(
    SnackBar(
      content: Text(texto),
      action: accion == null
          ? null
          : SnackBarAction(label: accion, onPressed: alPulsarAccion ?? () {}),
    ),
  );
}
