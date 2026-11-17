import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Vuelve a la pantalla anterior; si no hay (por ejemplo, al abrir la app
/// desde un enlace), va al inicio.
void volver(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/inicio');
  }
}
