import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/avisos.dart';
import '../../core/navegacion.dart';
import '../../core/validadores.dart';
import '../../models/vistas.dart';
import '../../providers/vistas_providers.dart';
import '../../viewmodels/taller_viewmodel.dart';
import '../../widgets/campo_selector.dart';
import '../../widgets/form_equipo.dart';
import '../../widgets/selectores.dart';

/// Recibir un equipo: se elige (o registra) el equipo y se anota la falla.
/// La orden nace "Recibida" y sin responsable; un técnico la toma después.
class OrdenFormScreen extends ConsumerStatefulWidget {
  const OrdenFormScreen({super.key, this.equipoId});

  /// Equipo ya elegido (viene desde su ficha).
  final int? equipoId;

  @override
  ConsumerState<OrdenFormScreen> createState() => _OrdenFormScreenState();
}

class _OrdenFormScreenState extends ConsumerState<OrdenFormScreen> {
  final _clave = GlobalKey<FormState>();
  final _falla = TextEditingController();
  late int? _equipoId = widget.equipoId;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _falla.dispose();
    super.dispose();
  }

  Future<void> _elegir(List<EquipoVista> equipos) async {
    final id = await elegirEquipo(context, equipos, seleccionado: _equipoId);
    if (id != null) setState(() => _equipoId = id);
  }

  Future<void> _equipoNuevo() async {
    final id = await mostrarFormEquipo(context);
    if (id != null) setState(() => _equipoId = id);
  }

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final r = await ref
        .read(tallerViewModelProvider)
        .crearOrden(equipoId: _equipoId!, falla: _falla.text);
    if (!mounted) return;
    if (r.ok) {
      mostrarAviso(context, 'Orden #${r.valor} registrada');
      context.pushReplacement('/orden/${r.valor}');
    } else {
      setState(() {
        _guardando = false;
        _error = r.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final equipos = ref.watch(equiposVistaProvider).value ?? const <EquipoVista>[];
    final actual = equipos.where((v) => v.equipo.id == _equipoId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => volver(context)),
        title: const Text('Nueva orden'),
      ),
      body: Form(
        key: _clave,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            CampoSelector(
              etiqueta: 'Equipo',
              valor: actual == null
                  ? null
                  : '${actual.equipo.marca} ${actual.equipo.modelo}',
              ayuda: actual == null
                  ? 'Un equipo puede volver al taller cuantas veces haga falta'
                  : 'Dueño: ${actual.cliente.nombre} · serie ${actual.equipo.serie}',
              onTap: () => _elegir(equipos),
              validator: () => _equipoId == null ? 'Elige el equipo' : null,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _equipoNuevo,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Registrar equipo nuevo'),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _falla,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Falla reportada',
                hintText: 'Ej.: No enciende, pantalla rota...',
                alignLabelWithHint: true,
              ),
              validator: Validadores.falla,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      size: 18, color: tema.colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_error!,
                        style: tema.textTheme.bodyMedium
                            ?.copyWith(color: tema.colorScheme.error)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Registrar orden'),
            ),
          ],
        ),
      ),
    );
  }
}
