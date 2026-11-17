import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/validadores.dart';
import '../data/app_database.dart';
import '../viewmodels/taller_viewmodel.dart';
import 'hoja_formulario.dart';

/// Hoja para registrar o editar un repuesto del inventario.
Future<int?> mostrarFormRepuesto(BuildContext context, {Repuesto? repuesto}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FormRepuesto(repuesto: repuesto),
  );
}

class _FormRepuesto extends ConsumerStatefulWidget {
  const _FormRepuesto({this.repuesto});

  final Repuesto? repuesto;

  @override
  ConsumerState<_FormRepuesto> createState() => _FormRepuestoState();
}

class _FormRepuestoState extends ConsumerState<_FormRepuesto> {
  final _clave = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.repuesto?.nombre);
  late final _codigo = TextEditingController(text: widget.repuesto?.codigo);
  late final _precio =
      TextEditingController(text: widget.repuesto?.precio.toString());
  late final _existencias =
      TextEditingController(text: widget.repuesto?.existencias.toString());
  late final _minimo =
      TextEditingController(text: (widget.repuesto?.minimo ?? 3).toString());
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    _precio.dispose();
    _existencias.dispose();
    _minimo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final r = await ref.read(tallerViewModelProvider).guardarRepuesto(
          existente: widget.repuesto,
          nombre: _nombre.text,
          codigo: _codigo.text,
          precio: int.parse(_precio.text.trim()),
          existencias: int.parse(_existencias.text.trim()),
          minimo: int.parse(_minimo.text.trim()),
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

  Widget _numero(TextEditingController c, String etiqueta,
      String? Function(String?) validador) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: etiqueta),
      validator: validador,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _clave,
      child: HojaFormulario(
        titulo: widget.repuesto == null ? 'Nuevo repuesto' : 'Editar repuesto',
        textoGuardar: 'Guardar',
        onGuardar: _guardar,
        guardando: _guardando,
        error: _error,
        hijos: [
          TextFormField(
            controller: _nombre,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (v) => Validadores.textoObligatorio(v, 'El nombre', max: 60),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _codigo,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Código'),
            validator: Validadores.codigo,
          ),
          const SizedBox(height: 14),
          _numero(_precio, 'Precio (\$)', Validadores.dineroPositivo),
          const SizedBox(height: 14),
          _numero(_existencias, 'Existencias',
              (v) => Validadores.enteroNoNegativo(v, 'Las existencias')),
          const SizedBox(height: 14),
          TextFormField(
            controller: _minimo,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Mínimo antes de alertar',
              helperText: 'Con esta cantidad o menos aparece "por agotarse"',
            ),
            validator: (v) => Validadores.enteroNoNegativo(v, 'El mínimo'),
          ),
        ],
      ),
    );
  }
}

/// Hoja para sumar unidades al inventario (llegó una compra).
Future<bool?> mostrarReponer(BuildContext context, Repuesto repuesto) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FormReponer(repuesto: repuesto),
  );
}

class _FormReponer extends ConsumerStatefulWidget {
  const _FormReponer({required this.repuesto});

  final Repuesto repuesto;

  @override
  ConsumerState<_FormReponer> createState() => _FormReponerState();
}

class _FormReponerState extends ConsumerState<_FormReponer> {
  final _clave = GlobalKey<FormState>();
  final _cantidad = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final r = await ref
        .read(tallerViewModelProvider)
        .reponer(widget.repuesto.id, int.parse(_cantidad.text.trim()));
    if (!mounted) return;
    if (r.ok) {
      Navigator.of(context).pop(true);
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
        titulo: 'Reponer existencias',
        subtitulo:
            '${widget.repuesto.nombre} · hay ${widget.repuesto.existencias}',
        textoGuardar: 'Añadir',
        onGuardar: _guardar,
        guardando: _guardando,
        error: _error,
        hijos: [
          TextFormField(
            controller: _cantidad,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Unidades que llegaron'),
            validator: Validadores.cantidadPositiva,
          ),
        ],
      ),
    );
  }
}
