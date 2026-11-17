import 'package:flutter/material.dart';

import '../core/texto_utils.dart';

/// Una opción de [mostrarSelectorLista].
class OpcionLista<T> {
  const OpcionLista({
    required this.valor,
    required this.titulo,
    this.subtitulo,
    this.icono,
  });

  final T valor;
  final String titulo;
  final String? subtitulo;
  final IconData? icono;
}

/// Hoja inferior con una lista donde buscar y elegir una opción.
Future<T?> mostrarSelectorLista<T>(
  BuildContext context, {
  required String titulo,
  required List<OpcionLista<T>> opciones,
  T? seleccionado,
  String vacio = 'No hay opciones disponibles.',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SelectorLista<T>(
      titulo: titulo,
      opciones: opciones,
      seleccionado: seleccionado,
      vacio: vacio,
    ),
  );
}

class _SelectorLista<T> extends StatefulWidget {
  const _SelectorLista({
    required this.titulo,
    required this.opciones,
    required this.seleccionado,
    required this.vacio,
  });

  final String titulo;
  final List<OpcionLista<T>> opciones;
  final T? seleccionado;
  final String vacio;

  @override
  State<_SelectorLista<T>> createState() => _SelectorListaState<T>();
}

class _SelectorListaState<T> extends State<_SelectorLista<T>> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final texto = normalizar(_busqueda.trim());
    final visibles = widget.opciones.where((o) {
      if (texto.isEmpty) return true;
      return normalizar('${o.titulo} ${o.subtitulo ?? ''}').contains(texto);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(widget.titulo, style: tema.textTheme.titleLarge),
            ),
            if (widget.opciones.length > 5)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            Flexible(
              child: visibles.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.opciones.isEmpty
                            ? widget.vacio
                            : 'Sin resultados para "$_busqueda".',
                        style: tema.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: visibles.length,
                      itemBuilder: (context, i) {
                        final o = visibles[i];
                        return ListTile(
                          leading: o.icono == null ? null : Icon(o.icono),
                          title: Text(o.titulo),
                          subtitle:
                              o.subtitulo == null ? null : Text(o.subtitulo!),
                          selected: o.valor == widget.seleccionado,
                          trailing: o.valor == widget.seleccionado
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => Navigator.of(context).pop(o.valor),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
