import 'package:flutter/material.dart';

/// Campo de búsqueda con botón para borrar el texto.
class CampoBusqueda extends StatelessWidget {
  const CampoBusqueda({
    super.key,
    required this.controlador,
    required this.sugerencia,
    required this.onChanged,
  });

  final TextEditingController controlador;
  final String sugerencia;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controlador,
      builder: (context, _) {
        return TextField(
          controller: controlador,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: sugerencia,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controlador.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controlador.clear();
                      onChanged('');
                    },
                  ),
          ),
        );
      },
    );
  }
}
