import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pinta un `AsyncValue` (lo que devuelven los providers de Riverpod) en
/// sus tres estados: cargando, error y dato.
class ValorAsincrono<T> extends StatelessWidget {
  const ValorAsincrono({super.key, required this.valor, required this.builder});

  final AsyncValue<T> valor;
  final Widget Function(T datos) builder;

  @override
  Widget build(BuildContext context) {
    return valor.when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No se pudieron cargar los datos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
