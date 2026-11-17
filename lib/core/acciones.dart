import 'package:flutter/material.dart';

import 'avisos.dart';
import 'resultado.dart';

/// Espera el resultado de una acción y avisa al usuario: el mensaje de éxito
/// si salió bien o el motivo del error si no. Devuelve si salió bien.
Future<bool> avisarResultado(
  BuildContext context,
  Future<Resultado<Object?>> accion, {
  String? exito,
}) async {
  final r = await accion;
  if (!context.mounted) return r.ok;
  if (r.ok) {
    if (exito != null) mostrarAviso(context, exito);
  } else {
    mostrarAviso(context, r.error ?? 'No se pudo completar la operación.');
  }
  return r.ok;
}
