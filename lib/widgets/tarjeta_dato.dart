import 'package:flutter/material.dart';

/// Tarjeta con una cifra destacada (para Inicio y Reportes).
class TarjetaDato extends StatelessWidget {
  const TarjetaDato({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.onTap,
    this.resaltar = false,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final VoidCallback? onTap;

  /// Usa el color de énfasis (para algo que requiere atención).
  final bool resaltar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final fondo = resaltar ? colores.tertiaryContainer : colores.surfaceContainer;
    final texto = resaltar ? colores.onTertiaryContainer : colores.onSurface;

    return Card(
      color: fondo,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, size: 22, color: texto),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valor,
                  style: tema.textTheme.titleLarge?.copyWith(color: texto),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                etiqueta,
                style: tema.textTheme.labelSmall?.copyWith(
                  color: texto.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
