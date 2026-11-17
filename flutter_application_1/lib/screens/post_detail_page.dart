import 'package:flutter/material.dart';

import '../core/acciones.dart';
import '../core/constants.dart';
import '../core/format.dart';
import '../core/rutas.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/comentario_model.dart';
import '../models/post_model.dart';
import '../services/comentario_service.dart';
import '../services/post_service.dart';
import '../widgets/poster_image.dart';
import '../widgets/star_rating.dart';

/// Detalle de una publicación: contenido, valoración, guardado y comentarios.
class PostDetailPage extends StatefulWidget {
  final int postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _posts = PostService();
  final _coments = ComentarioService();
  final _nuevo = TextEditingController();

  PostModel? _post;
  List<ComentarioModel> _comentarios = [];
  String? _error;
  bool _cargando = true;
  bool _enviando = false;
  bool _huboCambios = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nuevo.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await Future.wait([
        _posts.obtenerPost(widget.postId),
        _coments.obtenerComentarios(widget.postId),
      ]);
      if (!mounted) return;
      setState(() {
        _post = r[0] as PostModel;
        _comentarios = r[1] as List<ComentarioModel>;
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

  Future<void> _valorar(int puntos) async {
    if (!Session.logueado) {
      mostrarMensaje(context, 'Inicia sesión para valorar');
      return;
    }
    if (Session.usuario!.id == _post!.autorId) {
      mostrarMensaje(context, 'No puedes valorar tu propia publicación');
      return;
    }
    try {
      final r = await _posts.valorar(_post!.id, puntos);
      if (!mounted) return;
      setState(() {
        _post!.promedio = r.promedio;
        _post!.totalValoraciones = r.total;
        _post!.miValoracion = r.miValoracion;
        _huboCambios = true;
      });
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString());
    }
  }

  Future<void> _comentar() async {
    final texto = _nuevo.text.trim();
    if (texto.isEmpty) {
      mostrarMensaje(context, 'Escribe un comentario');
      return;
    }
    setState(() => _enviando = true);
    try {
      await _coments.agregarComentario(blogId: _post!.id, comentario: texto);
      _nuevo.clear();
      final lista = await _coments.obtenerComentarios(_post!.id);
      if (!mounted) return;
      setState(() {
        _comentarios = lista;
        _enviando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarMensaje(context, e.toString());
    }
  }

  Future<void> _eliminarComentario(ComentarioModel c) async {
    try {
      await _coments.eliminarComentario(c.id);
      if (!mounted) return;
      setState(() => _comentarios.removeWhere((x) => x.id == c.id));
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString());
    }
  }

  Future<void> _reaccionar(ComentarioModel c, String tipo) async {
    if (!Session.logueado) {
      mostrarMensaje(context, 'Inicia sesión para reaccionar');
      return;
    }
    try {
      final quitar = c.miReaccion == tipo;
      if (quitar) {
        await _coments.quitarReaccion(c.id);
      } else {
        await _coments.reaccionar(c.id, tipo);
      }
      final lista = await _coments.obtenerComentarios(_post!.id);
      if (!mounted) return;
      setState(() => _comentarios = lista);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString());
    }
  }

  Future<void> _editar() async {
    final cambio = await abrirFormulario(context, post: _post);
    if (cambio) {
      _huboCambios = true;
      _cargar();
    }
  }

  Future<void> _eliminar() async {
    final ok = await confirmarYEliminarPost(context, _post!);
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (pop, _) {
        if (!pop) Navigator.pop(context, _huboCambios);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context, _huboCambios),
          ),
          title: Text(_post?.etiquetaTipo ?? 'Publicación',
              style: estiloTitulo(size: 20)),
          actions: [
            if (_post != null && Session.puedeGestionar(_post!.autorId)) ...[
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: _editar,
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _eliminar,
              ),
            ],
          ],
        ),
        body: _cuerpo(),
      ),
    );
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null || _post == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'No se pudo cargar la publicación',
                style: const TextStyle(color: Colores.error)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final p = _post!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(builder: (context, c) {
                final poster = ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 200,
                    height: 290,
                    child: PosterImage(
                        url: p.imagen, titulo: p.titulo, semilla: p.id),
                  ),
                );
                final info = _info(p);
                if (c.maxWidth < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: poster),
                      const SizedBox(height: 16),
                      info,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    poster,
                    const SizedBox(width: 22),
                    Expanded(child: info),
                  ],
                );
              }),
              const SizedBox(height: 24),
              SelectableText(p.descripcion,
                  style: const TextStyle(fontSize: 15.5, height: 1.6)),
              if (p.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: p.tags
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .map((t) => Chip(label: Text('#$t')))
                      .toList(),
                ),
              ],
              const Divider(height: 40),
              Text('Comentarios (${_comentarios.length})',
                  style: estiloTitulo(size: 20)),
              const SizedBox(height: 14),
              _cajaComentario(),
              const SizedBox(height: 14),
              if (_comentarios.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Aún no hay comentarios. ¡Sé el primero!',
                      style: TextStyle(color: Colores.textoSuave)),
                ),
              ..._comentarios.map(_tarjetaComentario),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(PostModel p) {
    final propia = Session.logueado && Session.usuario!.id == p.autorId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.meta,
            style: const TextStyle(
                color: Colores.rojo, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(p.tituloConAnio, style: estiloTitulo(size: 30)),
        const SizedBox(height: 10),
        Row(
          children: [
            Avatar(texto: p.autor ?? 'C', radio: 13),
            const SizedBox(width: 8),
            Text('${p.autorAlias} · ${fechaCorta(p.fecha)}',
                style: const TextStyle(color: Colores.textoSuave)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            StarsDisplay(valor: p.promedio, size: 20),
            const SizedBox(width: 8),
            Text(
              p.promedio == null
                  ? 'Sin valoraciones'
                  : '${p.promedio!.toStringAsFixed(1)} (${p.totalValoraciones})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(propia ? 'No puedes valorar tu propia publicación' : 'Tu valoración',
            style: const TextStyle(color: Colores.textoSuave, fontSize: 13)),
        if (!propia)
          StarsInput(valor: p.miValoracion ?? 0, onChanged: _valorar, size: 30),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => alternarGuardado(context, p, () {
            setState(() {});
            _huboCambios = true;
          }),
          icon: Icon(p.guardado
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded),
          label: Text(p.guardado ? 'Guardado' : 'Guardar'),
        ),
      ],
    );
  }

  Widget _cajaComentario() {
    if (!Session.logueado) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colores.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colores.borde),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text('Inicia sesión para comentar, valorar y reaccionar.',
                  style: TextStyle(color: Colores.textoSuave)),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (r) => false),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: _nuevo,
          maxLength: 500,
          maxLines: 3,
          minLines: 2,
          decoration: const InputDecoration(labelText: 'Escribe un comentario'),
        ),
        ElevatedButton(
          onPressed: _enviando ? null : _comentar,
          child: _enviando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white))
              : const Text('Comentar'),
        ),
      ],
    );
  }

  Widget _tarjetaComentario(ComentarioModel c) {
    final puede = Session.puedeGestionar(c.usuarioId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(texto: c.autor, radio: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Text(c.autorAlias,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text(tiempoRelativo(c.fecha),
                  style: const TextStyle(
                      color: Colores.textoSuave, fontSize: 12)),
              if (puede)
                IconButton(
                  tooltip: 'Eliminar comentario',
                  iconSize: 18,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _eliminarComentario(c),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(c.comentario, style: const TextStyle(height: 1.45)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: reaccionesDisponibles.entries.map((e) {
              final cuenta = c.reacciones[e.key] ?? 0;
              final mia = c.miReaccion == e.key;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _reaccionar(c, e.key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: mia ? const Color(0x33D62828) : Colores.superficie2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: mia ? Colores.rojo : Colores.borde),
                  ),
                  child: Text(cuenta > 0 ? '${e.value} $cuenta' : e.value,
                      style: const TextStyle(fontSize: 13)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
