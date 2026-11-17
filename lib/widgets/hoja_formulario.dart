import 'package:flutter/material.dart';

/// Estructura común de las hojas inferiores con formulario: título, campos,
/// un mensaje de error opcional y los botones Cancelar / Guardar.
/// Las hojas se cierran con `Navigator.of(context).pop(valor)`.
class HojaFormulario extends StatelessWidget {
  const HojaFormulario({
    super.key,
    required this.titulo,
    required this.hijos,
    required this.textoGuardar,
    required this.onGuardar,
    this.subtitulo,
    this.error,
    this.guardando = false,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> hijos;
  final String textoGuardar;
  final VoidCallback onGuardar;
  final String? error;
  final bool guardando;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: tema.textTheme.titleLarge),
            if (subtitulo != null) ...[
              const SizedBox(height: 4),
              Text(subtitulo!, style: tema.textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            ...hijos,
            if (error != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      size: 18, color: tema.colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error!,
                      style: tema.textTheme.bodyMedium
                          ?.copyWith(color: tema.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        guardando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: guardando ? null : onGuardar,
                    child: guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(textoGuardar),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
