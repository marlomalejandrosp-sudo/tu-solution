import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Une dos `AsyncValue` en uno: cuando ambos tienen dato aplica [f]; si
/// alguno falló propaga el error; si no, sigue cargando.
AsyncValue<R> combinar2<A, B, R>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  R Function(A, B) f,
) {
  if (a.hasValue && b.hasValue) {
    return AsyncData(f(a.requireValue, b.requireValue));
  }
  if (a.hasError) return AsyncError(a.error!, a.stackTrace ?? StackTrace.empty);
  if (b.hasError) return AsyncError(b.error!, b.stackTrace ?? StackTrace.empty);
  return const AsyncLoading();
}

/// Igual que [combinar2] con tres fuentes.
AsyncValue<R> combinar3<A, B, C, R>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  AsyncValue<C> c,
  R Function(A, B, C) f,
) {
  if (a.hasValue && b.hasValue && c.hasValue) {
    return AsyncData(f(a.requireValue, b.requireValue, c.requireValue));
  }
  if (a.hasError) return AsyncError(a.error!, a.stackTrace ?? StackTrace.empty);
  if (b.hasError) return AsyncError(b.error!, b.stackTrace ?? StackTrace.empty);
  if (c.hasError) return AsyncError(c.error!, c.stackTrace ?? StackTrace.empty);
  return const AsyncLoading();
}
