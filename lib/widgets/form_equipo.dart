import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/estado_colores.dart';
import '../core/validadores.dart';
import '../data/app_database.dart';
import '../models/enums.dart';
import '../providers/base_providers.dart';
import '../viewmodels/taller_viewmodel.dart';
import 'campo_selector.dart';
import 'form_cliente.dart';
import 'hoja_formulario.dart';
import 'selectores.dart';

/// Hoja para registrar o editar un equipo. Si ya se conoce al dueño se pasa
/// [clienteId]. Devuelve el id del equipo guardado.
Future<int?> mostrarFormEquipo(
  BuildContext context, {
  Equipo? equipo,
  int? clienteId,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FormEquipo(equipo: equipo, clienteId: clienteId),
  );
}

class _FormEquipo extends ConsumerStatefulWidget {
  const _FormEquipo({this.equipo, this.clienteId});

  final Equipo? equipo;
  final int? clienteId;

  @override
  ConsumerState<_FormEquipo> createState() => _FormEquipoState();
}

class _FormEquipoState extends ConsumerState<_FormEquipo> {
  final _clave = GlobalKey<FormState>();
  late final _marca = TextEditingController(text: widget.equipo?.marca);
  late final _modelo = TextEditingController(text: widget.equipo?.modelo);
  late final _serie = TextEditingController(text: widget.equipo?.serie);
  late TipoEquipo _tipo = widget.equipo?.tipo ?? TipoEquipo.celular;
  late int? _clienteId = widget.equipo?.clienteId ?? widget.clienteId;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _marca.dispose();
    _modelo.dispose();
    _serie.dispose();
    super.dispose();
  }

  Future<void> _elegirCliente(List<Cliente> clientes) async {
    final id = await elegirCliente(context, clientes, seleccionado: _clienteId);
    if (id != null) setState(() => _clienteId = id);
  }

  Future<void> _clienteNuevo() async {
    final id = await mostrarFormCliente(context);
    if (id != null) setState(() => _clienteId = id);
  }

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final r = await ref.read(tallerViewModelProvider).guardarEquipo(
          existente: widget.equipo,
          clienteId: _clienteId!,
          tipo: _tipo,
          marca: _marca.text,
          modelo: _modelo.text,
          serie: _serie.text,
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
    final clientes = ref.watch(clientesProvider).value ?? const <Cliente>[];
    final actual = clientes.where((c) => c.id == _clienteId).firstOrNull;

    return Form(
      key: _clave,
      child: HojaFormulario(
        titulo: widget.equipo == null ? 'Nuevo equipo' : 'Editar equipo',
        textoGuardar: 'Guardar',
        onGuardar: _guardar,
        guardando: _guardando,
        error: _error,
        hijos: [
          CampoSelector(
            etiqueta: 'Dueño',
            valor: actual?.nombre,
            onTap: () => _elegirCliente(clientes),
            validator: () => _clienteId == null ? 'Elige al dueño' : null,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _clienteNuevo,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Cliente nuevo'),
            ),
          ),
          const SizedBox(height: 6),
          Text('Tipo de equipo', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final t in TipoEquipo.values)
                ChoiceChip(
                  avatar: Icon(t.icono, size: 18),
                  label: Text(t.etiqueta),
                  selected: _tipo == t,
                  onSelected: (_) => setState(() => _tipo = t),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _marca,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Marca'),
            validator: (v) => Validadores.textoObligatorio(v, 'La marca'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _modelo,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Modelo'),
            validator: (v) => Validadores.textoObligatorio(v, 'El modelo'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _serie,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Número de serie',
              helperText: 'Identifica al equipo cuando vuelva al taller',
            ),
            validator: Validadores.serie,
          ),
        ],
      ),
    );
  }
}
