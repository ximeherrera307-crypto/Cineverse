import 'dart:async';

import 'package:flutter/material.dart';

import '../core/acciones.dart';
import '../core/format.dart';
import '../core/rutas.dart';
import '../core/theme.dart';
import '../models/comentario_model.dart';
import '../models/home_model.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/poster_card.dart';
import '../widgets/poster_image.dart';
import '../widgets/review_tile.dart';
import '../widgets/star_rating.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _servicio = PostService();
  final _pager = PageController();
  Timer? _timer;

  HomeModel? _home;
  List<PostModel> _ultimas = [];
  String? _filtro; // null = todas
  String? _error;
  bool _cargando = true;
  int _slide = 0;

  static const _filtros = <String, String?>{
    'Todas': null,
    'Películas': 'pelicula',
    'Series': 'serie',
    'Artículos': 'articulo',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      final n = _home?.destacados.length ?? 0;
      if (n > 1 && _pager.hasClients) {
        _pager.animateToPage((_slide + 1) % n,
            duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pager.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await Future.wait([
        _servicio.obtenerInicio(),
        _servicio.obtenerPosts(tipo: _filtro, limit: 8),
      ]);
      if (!mounted) return;
      setState(() {
        _home = r[0] as HomeModel;
        _ultimas = r[1] as List<PostModel>;
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

  Future<void> _cambiarFiltro(String? tipo) async {
    setState(() => _filtro = tipo);
    try {
      final l = await _servicio.obtenerPosts(tipo: tipo, limit: 8);
      if (mounted) setState(() => _ultimas = l);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString());
    }
  }

  Future<void> _abrir(PostModel p) async {
    if (await abrirDetalle(context, p)) _cargar();
  }

  Future<void> _accion(PostModel p, AccionReview a) async {
    switch (a) {
      case AccionReview.guardar:
        await alternarGuardado(context, p, () {
          if (mounted) setState(() {});
        });
      case AccionReview.editar:
        if (await abrirFormulario(context, post: p)) _cargar();
      case AccionReview.eliminar:
        if (await confirmarYEliminarPost(context, p)) _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(ruta: '/home', child: _cuerpo());
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null || _home == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42, color: Colores.textoSuave),
            const SizedBox(height: 10),
            Text(_error ?? 'No se pudo cargar el inicio',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colores.error)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, c) {
      final ancho = c.maxWidth >= 1150;
      final principal = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(),
          const SizedBox(height: 28),
          _tendencias(),
          const SizedBox(height: 28),
          _ultimasResenas(),
        ],
      );
      final lateral = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_estrenos(), const SizedBox(height: 24), _comentarios()],
      );

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ancho
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: principal),
                  const SizedBox(width: 24),
                  SizedBox(width: 320, child: lateral),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [principal, const SizedBox(height: 28), lateral],
              ),
      );
    });
  }

  // ---------- Destacado ----------
  Widget _hero() {
    final lista = _home!.destacados;
    if (lista.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colores.superficie,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colores.borde),
        ),
        child: const Text('Aún no hay publicaciones destacadas',
            style: TextStyle(color: Colores.textoSuave)),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: PageView.builder(
              controller: _pager,
              itemCount: lista.length,
              onPageChanged: (i) => setState(() => _slide = i),
              itemBuilder: (_, i) {
                final p = lista[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    PosterImage(url: p.imagen, titulo: p.titulo, semilla: p.id),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xEE0A0A0C), Color(0x330A0A0C)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('DESTACADO',
                              style: TextStyle(
                                  color: Colores.rojo,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(p.tituloConAnio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: estiloTitulo(size: 32)),
                          const SizedBox(height: 4),
                          Text(p.meta,
                              style: const TextStyle(color: Colores.textoSuave)),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () => _abrir(p),
                            child: const Text('Explorar reseñas'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            lista.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 7,
              width: i == _slide ? 22 : 7,
              decoration: BoxDecoration(
                color: i == _slide ? Colores.rojo : Colores.borde,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _titulo(String texto, {VoidCallback? verTodo}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: Text(texto, style: estiloTitulo(size: 22))),
          if (verTodo != null)
            TextButton(onPressed: verTodo, child: const Text('Ver todo')),
        ],
      ),
    );
  }

  // ---------- Tendencias ----------
  Widget _tendencias() {
    final lista = _home!.tendencias;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Tendencias en Cineverse'),
        if (lista.isEmpty)
          const Text('Aún no hay tendencias.',
              style: TextStyle(color: Colores.textoSuave))
        else
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => PosterCard(
                post: lista[i],
                onTap: () => _abrir(lista[i]),
                onGuardar: () => alternarGuardado(context, lista[i], () {
                  if (mounted) setState(() {});
                }),
              ),
            ),
          ),
      ],
    );
  }

  // ---------- Últimas reseñas ----------
  Widget _ultimasResenas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Últimas reseñas'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _filtros.entries.map((e) {
            final activo = _filtro == e.value;
            return ChoiceChip(
              label: Text(e.key),
              selected: activo,
              showCheckmark: false,
              selectedColor: Colores.rojo,
              backgroundColor: Colores.superficie,
              side: BorderSide(color: activo ? Colores.rojo : Colores.borde),
              labelStyle: TextStyle(
                  color: activo ? Colors.white : Colores.texto,
                  fontWeight: FontWeight.w600),
              onSelected: (_) => _cambiarFiltro(e.value),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        if (_ultimas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No hay reseñas en esta categoría todavía.',
                style: TextStyle(color: Colores.textoSuave)),
          ),
        ..._ultimas.map((p) => ReviewTile(
              post: p,
              onTap: () => _abrir(p),
              onAccion: (a) => _accion(p, a),
            )),
      ],
    );
  }

  // ---------- Columna derecha ----------
  Widget _caja(Widget hijo) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colores.superficie,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colores.borde),
        ),
        child: hijo,
      );

  Widget _estrenos() {
    final lista = _home!.estrenos;
    return _caja(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estrenos del mes', style: estiloTitulo(size: 19)),
        const SizedBox(height: 12),
        if (lista.isEmpty)
          const Text('Sin estrenos por ahora.',
              style: TextStyle(color: Colores.textoSuave)),
        ...lista.map((p) => InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _abrir(p),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 46,
                        height: 64,
                        child: PosterImage(
                            url: p.imagen, titulo: p.titulo, semilla: p.id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(p.meta,
                              style: const TextStyle(
                                  color: Colores.textoSuave, fontSize: 12)),
                          const SizedBox(height: 2),
                          PromedioChip(promedio: p.promedio, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    ));
  }

  Widget _comentarios() {
    final lista = _home!.comentarios;
    return _caja(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comentarios recientes', style: estiloTitulo(size: 19)),
        const SizedBox(height: 12),
        if (lista.isEmpty)
          const Text('Aún no hay comentarios.',
              style: TextStyle(color: Colores.textoSuave)),
        ...lista.map(_filaComentario),
      ],
    ));
  }

  Widget _filaComentario(ComentarioModel c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(texto: c.autor, radio: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(c.autorAlias,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    Text(tiempoRelativo(c.fecha),
                        style: const TextStyle(
                            color: Colores.textoSuave, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(c.comentario,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
