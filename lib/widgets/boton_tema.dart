import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/tema_viewmodel.dart';

/// Botón de la barra superior que cambia entre tema claro y oscuro.
class BotonTema extends ConsumerWidget {
  const BotonTema({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brillo = Theme.of(context).brightness;
    return IconButton(
      tooltip: 'Cambiar tema',
      onPressed: () => ref.read(temaProvider.notifier).alternar(brillo),
      icon: Icon(
        brillo == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      ),
    );
  }
}
