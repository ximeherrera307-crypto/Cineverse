import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'session.dart';

/// Llave global para poder volver al login si la sesión expira.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiException implements Exception {
  final String mensaje;
  final int? codigo;

  ApiException(this.mensaje, [this.codigo]);

  @override
  String toString() => mensaje;
}

/// Cliente HTTP único: agrega el token, decodifica UTF-8 y traduce errores.
class Api {
  // En Flutter Web en la misma computadora funciona 127.0.0.1.
  // Para emulador Android usa http://10.0.2.2:8000
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const Duration _espera = Duration(seconds: 12);

  static Map<String, String> _headers({bool json = false}) {
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (Session.token != null) 'Authorization': 'Bearer ${Session.token}',
    };
  }

  static Uri _uri(String ruta, [Map<String, String?>? query]) {
    final limpio = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.isNotEmpty) limpio[k] = v;
    });
    return Uri.parse('$baseUrl$ruta').replace(
      queryParameters: limpio.isEmpty ? null : limpio,
    );
  }

  static Future<dynamic> get(String ruta, {Map<String, String?>? query}) {
    return _enviar(() => http.get(_uri(ruta, query), headers: _headers()));
  }

  static Future<dynamic> post(String ruta, {Object? body}) {
    return _enviar(() => http.post(
          _uri(ruta),
          headers: _headers(json: true),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  static Future<dynamic> put(String ruta, {Object? body}) {
    return _enviar(() => http.put(
          _uri(ruta),
          headers: _headers(json: true),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  static Future<dynamic> delete(String ruta) {
    return _enviar(() => http.delete(_uri(ruta), headers: _headers()));
  }

  /// Sube un archivo (multipart) en el campo [campo].
  static Future<dynamic> subirArchivo(
    String ruta, {
    required String campo,
    required List<int> bytes,
    required String nombre,
  }) {
    return _enviar(() async {
      final peticion = http.MultipartRequest('POST', _uri(ruta))
        ..headers.addAll(_headers())
        ..files.add(http.MultipartFile.fromBytes(campo, bytes, filename: nombre));
      return http.Response.fromStream(await peticion.send());
    });
  }

  static Future<dynamic> _enviar(Future<http.Response> Function() peticion) async {
    final http.Response respuesta;
    try {
      respuesta = await peticion().timeout(_espera);
    } on TimeoutException {
      throw ApiException(
        'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw ApiException(
        'No se pudo conectar con el servidor. Verifica que la API esté encendida.',
      );
    }

    dynamic cuerpo;
    if (respuesta.bodyBytes.isNotEmpty) {
      try {
        cuerpo = jsonDecode(utf8.decode(respuesta.bodyBytes));
      } catch (_) {
        cuerpo = null;
      }
    }

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return cuerpo;
    }

    // Sesión vencida: se limpia y se regresa al login.
    if (respuesta.statusCode == 401 && Session.token != null) {
      Session.limpiar();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (ruta) => false);
    }

    throw ApiException(_mensajeDeError(cuerpo, respuesta.statusCode), respuesta.statusCode);
  }

  static String _mensajeDeError(dynamic cuerpo, int codigo) {
    if (cuerpo is Map && cuerpo['detail'] != null) {
      final detalle = cuerpo['detail'];
      if (detalle is String) return detalle;
      if (detalle is List && detalle.isNotEmpty) {
        final primero = detalle.first;
        if (primero is Map && primero['msg'] != null) {
          return primero['msg']
              .toString()
              .replaceFirst('Value error, ', '')
              .replaceFirst('String should have at least', 'Debe tener al menos');
        }
      }
    }
    return 'Ocurrió un error (HTTP $codigo)';
  }
}
