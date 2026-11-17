import 'package:flutter/material.dart';

import '../core/acciones.dart';
import '../core/rutas.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/review_tile.dart';

/// Listado genérico: películas, series, artículos, mis reseñas,
/// guardados o resultados de búsqueda.
class ListadoPage extends StatefulWidget {
  final String ruta;
  final String titulo;
  final String? tipo;
  final bool mias;
  final bool guardados;
  final String? consulta;

  const ListadoPage({
    super.key,
    required this.ruta,
    required this.titulo,
    this.tipo,
    this.mias = false,
    this.guardados = false,
    this.consulta,
  });

  @override
  State<ListadoPage> createState() => _ListadoPageState();
}

class _ListadoPageState extends State<ListadoPage> {
  static const _pagina = 20;
  final _servicio = PostService();
  final List<PostModel> _posts = [];

  String _orden = 'recientes';
  bool _cargando = true;
  bool _hayMas = false;
  String? _error;

  bool get _requiereSesion => widget.mias || widget.guardados;

  @override
  void initState() {
    super.initState();
    _cargar(reiniciar: true);
  }

  Future<void> _cargar({bool reiniciar = false}) async {
    if (_requiereSesion && !Session.logueado) {
      setState(() => _cargando = false);
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
      if (reiniciar) _posts.clear();
    });
    try {
      final lote = await _servicio.obtenerPosts(
        q: widget.consulta,
        tipo: widget.tipo,
        mias: widget.mias,
        guardados: widget.guardados,
        orden: _orden,
        limit: _pagina,
        offset: _posts.length,
      );
      if (!mounted) return;
      setState(() {
        _posts.addAll(lote);
        _hayMas = lote.length == _pagina;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _accion(PostModel p, AccionReview a) async {
    switch (a) {
      case AccionReview.guardar:
        await alternarGuardado(context, p, () {
          if (!mounted) return;
          setState(() {
            if (widget.guardados && !p.guardado) _posts.remove(p);
          });
        });
      case AccionReview.editar:
        if (await abrirFormulario(context, post: p)) _cargar(reiniciar: true);
      case AccionReview.eliminar:
        if (await confirmarYEliminarPost(context, p)) {
          if (mounted) setState(() => _posts.remove(p));
        }
    }
  }

  String get _vacio {
    if (widget.guardados) return 'Todavía no has guardado publicaciones.';
    if (widget.mias) return 'Aún no has publicado reseñas.';
    if (widget.consulta != null) return 'No hay resultados para "${widget.consulta}".';
    return 'Todavía no hay publicaciones en esta sección.';
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      ruta: widget.ruta,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.consulta != null
                      ? 'Resultados para "${widget.consulta}"'
                      : widget.titulo,
                  style: estiloTitulo(size: 28),
                ),
              ),
              DropdownButton<String>(
                value: _orden,
                underline: const SizedBox.shrink(),
                dropdownColor: Colores.superficie2,
                items: const [
                  DropdownMenuItem(value: 'recientes', child: Text('Más recientes')),
                  DropdownMenuItem(value: 'mejor', child: Text('Mejor valoradas')),
                ],
                onChanged: (v) {
                  _orden = v ?? 'recientes';
                  _cargar(reiniciar: true);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_requiereSesion && !Session.logueado)
            _mensaje('Inicia sesión para ver esta sección.',
                accion: 'Iniciar sesión',
                alPulsar: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (r) => false))
          else if (_error != null)
            _mensaje(_error!, accion: 'Reintentar',
                alPulsar: () => _cargar(reiniciar: true), error: true)
          else if (!_cargando && _posts.isEmpty)
            _mensaje(_vacio),
          ..._posts.map((p) => ReviewTile(
                post: p,
                onTap: () async {
                  if (await abrirDetalle(context, p)) _cargar(reiniciar: true);
                },
                onAccion: (a) => _accion(p, a),
              )),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_hayMas && !_cargando)
            Center(
              child: OutlinedButton(
                onPressed: () => _cargar(),
                child: const Text('Cargar más'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mensaje(String texto,
      {String? accion, VoidCallback? alPulsar, bool error = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Text(texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: error ? Colores.error : Colores.textoSuave)),
          if (accion != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: alPulsar, child: Text(accion)),
          ],
        ],
      ),
    );
  }
}
