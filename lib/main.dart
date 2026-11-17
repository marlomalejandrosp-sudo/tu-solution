import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // ProviderScope es el "contenedor" de Riverpod: guarda todos los providers.
  runApp(const ProviderScope(child: TuSolutionApp()));
}
