import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/validadores.dart';
import '../data/app_database.dart';
import '../viewmodels/taller_viewmodel.dart';
import 'hoja_formulario.dart';

/// Hoja para registrar o editar un cliente. Devuelve el id guardado.
Future<int?> mostrarFormCliente(BuildContext context, {Cliente? cliente}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FormCliente(cliente: cliente),
  );
}

class _FormCliente extends ConsumerStatefulWidget {
  const _FormCliente({this.cliente});

  final Cliente? cliente;

  @override
  ConsumerState<_FormCliente> createState() => _FormClienteState();
}

class _FormClienteState extends ConsumerState<_FormCliente> {
  final _clave = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.cliente?.nombre);
  late final _telefono = TextEditingController(text: widget.cliente?.telefono);
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final r = await ref.read(tallerViewModelProvider).guardarCliente(
          existente: widget.cliente,
          nombre: _nombre.text,
          telefono: _telefono.text,
        );
    if (!mounted) return;
    if (r.ok) {
      Navigator.of(context).pop(r.valor);
    } else {
      setState(() {
        _guardando = false;
        _error = r.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _clave,
      child: HojaFormulario(
        titulo: widget.cliente == null ? 'Nuevo cliente' : 'Editar cliente',
        textoGuardar: 'Guardar',
        onGuardar: _guardar,
        guardando: _guardando,
        error: _error,
        hijos: [
          TextFormField(
            controller: _nombre,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nombre completo'),
            validator: (v) => Validadores.nombre(v),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _telefono,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 8,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              helperText: '8 dígitos',
            ),
            validator: Validadores.telefono,
          ),
        ],
      ),
    );
  }
}
