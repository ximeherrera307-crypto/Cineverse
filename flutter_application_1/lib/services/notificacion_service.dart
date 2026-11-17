import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../models/notificacion_model.dart';

/// Notificaciones de la campana. El contador se actualiza solo cada 45 s.
class NotificacionService {
  /// Cantidad de avisos sin leer (la campana escucha este valor).
  static final ValueNotifier<int> noLeidas = ValueNotifier<int>(0);
  static Timer? _timer;

  /// Arranca la consulta periódica (se puede llamar varias veces).
  static void iniciar() {
    if (!Session.logueado) {
      detener();
      return;
    }
    actualizarContador();
    _timer ??= Timer.periodic(
      const Duration(seconds: 45),
      (_) => actualizarContador(),
    );
  }

  static void detener() {
    _timer?.cancel();
    _timer = null;
    noLeidas.value = 0;
  }

  static Future<void> actualizarContador() async {
    if (!Session.logueado) {
      detener();
      return;
    }
    try {
      final datos = await Api.get('/notificaciones', query: {'limit': '1'})
          as Map<String, dynamic>;
      noLeidas.value = (datos['no_leidas'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Si falla la red, se conserva el número anterior.
    }
  }

  Future<List<NotificacionModel>> obtener() async {
    final datos = await Api.get('/notificaciones', query: {'limit': '30'})
        as Map<String, dynamic>;
    noLeidas.value = (datos['no_leidas'] as num?)?.toInt() ?? 0;
    return (datos['items'] as List)
        .map((e) => NotificacionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> marcarLeidas() async {
    await Api.post('/notificaciones/leidas');
    noLeidas.value = 0;
  }

  Future<void> borrarTodas() async {
    await Api.delete('/notificaciones');
    noLeidas.value = 0;
  }
}
