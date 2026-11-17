import 'package:flutter/material.dart';

/// Encabezado de una sección, con un texto opcional a la derecha.
class SeccionTitulo extends StatelessWidget {
  const SeccionTitulo(this.texto, {super.key, this.lateral});

  final String texto;
  final Widget? lateral;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Row(
        children: [
          Expanded(child: Text(texto, style: tema.textTheme.titleMedium)),
          ?lateral,
        ],
      ),
    );
  }
}
