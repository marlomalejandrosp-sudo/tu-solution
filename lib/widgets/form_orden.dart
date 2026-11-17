import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formato.dart';
import '../core/validadores.dart';
import '../data/app_database.dart';
import '../providers/base_providers.dart';
import '../viewmodels/taller_viewmodel.dart';
import 'campo_selector.dart';
import 'hoja_formulario.dart';
import 'selectores.dart';

/// Hoja para editar la falla reportada de una orden abierta.
Future<bool?> mostrarEditarFalla(
    BuildContext context, int ordenId, String fallaActual) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FormFalla(ordenId: ordenId, fallaActual: fallaActual),
  );
}

class _FormFalla extends ConsumerStatefulWidget {
  const _FormFalla({required this.ordenId, required this.fallaActual});

  final int ordenId;
  final String fallaActual;

  @override
  ConsumerState<_FormFalla> createState() => _FormFallaState();
}

class _FormFallaState extends ConsumerState<_FormFalla> {
  final _clave = GlobalKey<FormState>();
  late final _falla = TextEditingController(text: widget.fallaActual);
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _falla.dispose();
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
        .editarFalla(widget.ordenId, _falla.text);
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
        titulo: 'Falla reportada',
        textoGuardar: 'Guardar',
        onGuardar: _guardar,
        guardando: _guardando,
        error: _error,
        hijos: [
          TextFormField(
            controller: _falla,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Descripción'),
            validator: Validadores.falla,
          ),
        ],
      ),
    );
  }
}

/// Hoja para anotar un trabajo realizado y su costo de mano de obra.
Future<bool?> mostrarFormTrabajo(BuildContext context, int ordenId) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FormTrabajo(ordenId: ordenId),
  );
}

class _FormTrabajo extends ConsumerStatefulWidget {
  const _FormTrabajo({required this.ordenId});

  final int ordenId;

  @override
  ConsumerState<_FormTrabajo> createState() => _FormTrabajoState();
}

class _FormTrabajoState extends ConsumerState<_FormTrabajo> {
  final _clave = GlobalKey<FormState>();
  final _descripcion = TextEditingController();
  final _costo = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _descripcion.dispose();
    _costo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final r = await ref.read(tallerViewModelProvider).agregarTrabajo(
          ordenId: widget.ordenId,
          descripcion: _descripcion.text,
          costo: int.parse(_costo.text.trim()),
        );
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
        titulo: 'Registrar trabajo',
        textoGuardar: 'Añadir',
        onGuardar: _guardar,
        guardando: _guardando,
        error: _error,
        hijos: [
          TextFormField(
            controller: _descripcion,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Trabajo realizado',
              hintText: 'Ej.: Cambio de pantalla',
            ),
            validator: (v) =>
                Validadores.textoObligatorio(v, 'El trabajo', max: 80),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _costo,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Mano de obra (\$)'),
            validator: Validadores.dineroPositivo,
          ),
        ],
      ),
    );
  }
}

/// Hoja para usar un repuesto del inventario en la orden (baja el stock).
Future<bool?> mostrarFormUsarRepuesto(BuildContext context, int ordenId) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FormUsarRepuesto(ordenId: ordenId),
  );
}

class _FormUsarRepuesto extends ConsumerStatefulWidget {
  const _FormUsarRepuesto({required this.ordenId});

  final int ordenId;

  @override
  ConsumerState<_FormUsarRepuesto> createState() => _FormUsarRepuestoState();
}

class _FormUsarRepuestoState extends ConsumerState<_FormUsarRepuesto> {
  final _clave = GlobalKey<FormState>();
  final _cantidad = TextEditingController(text: '1');
  int? _repuestoId;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  Future<void> _elegir(List<Repuesto> repuestos) async {
    final id = await elegirRepuesto(context, repuestos);
    if (id != null) setState(() => _repuestoId = id);
  }

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final r = await ref.read(tallerViewModelProvider).agregarRepuesto(
          ordenId: widget.ordenId,
          repuestoId: _repuestoId!,
          cantidad: int.parse(_cantidad.text.trim()),
        );
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
    final repuestos = ref.watch(repuestosProvider).value ?? const <Repuesto>[];
    final actual = repuestos.where((r) => r.id == _repuestoId).firstOrNull;

    return Form(
      key: _clave,
      child: HojaFormulario(
        titulo: 'Usar repuesto',
        subtitulo: 'Las unidades se descuentan del inventario.',
        textoGuardar: 'Añadir',
        onGuardar: _guardar,
        guardando: _guardando,
        error: _error,
        hijos: [
          CampoSelector(
            etiqueta: 'Repuesto',
            valor: actual?.nombre,
            ayuda: actual == null
                ? null
                : '${Formato.dinero(actual.precio)} c/u · '
                    '${actual.existencias} disponibles',
            onTap: () => _elegir(repuestos),
            validator: () => _repuestoId == null ? 'Elige un repuesto' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cantidad,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Cantidad'),
            validator: Validadores.cantidadPositiva,
          ),
        ],
      ),
    );
  }
}
