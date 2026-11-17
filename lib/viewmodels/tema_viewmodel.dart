import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modo de tema de la app. Empieza siguiendo el del sistema.
class TemaViewModel extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void alternar(Brightness actual) {
    state = actual == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final temaProvider =
    NotifierProvider<TemaViewModel, ThemeMode>(TemaViewModel.new);
