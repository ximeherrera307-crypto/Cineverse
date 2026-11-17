import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/rutas.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/notificacion_model.dart';
import '../services/auth_service.dart';
import '../services/notificacion_service.dart';
import 'poster_image.dart';

/// Marco de la app: barra lateral + barra superior (como en el boceto).
/// En pantallas angostas la barra lateral pasa a un menú desplegable.
class AppShell extends StatefulWidget {
  final String ruta;
  final Widget child;

  const AppShell({super.key, required this.ruta, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _ItemNav {
  final IconData icono;
  final String texto;
  final String ruta;

  const _ItemNav(this.icono, this.texto, this.ruta);
}

class _AppShellState extends State<AppShell> {
  final TextEditingController _buscar = TextEditingController();

  static const _principales = [
    _ItemNav(Icons.home_rounded, 'Inicio', '/home'),
    _ItemNav(Icons.movie_outlined, 'Películas', '/peliculas'),
    _ItemNav(Icons.live_tv_outlined, 'Series', '/series'),
    _ItemNav(Icons.article_outlined, 'Artículos', '/articulos'),
  ];

  static const _personales = [
    _ItemNav(Icons.star_border_rounded, 'Mis reseñas', '/mis-resenas'),
    _ItemNav(Icons.bookmark_border_rounded, 'Guardados', '/guardados'),
  ];

  static const _cuenta = [
    _ItemNav(Icons.person_outline_rounded, 'Mi perfil', '/perfil'),
    _ItemNav(Icons.settings_outlined, 'Configuración', '/config'),
  ];

  static const _admin = [
    _ItemNav(Icons.people_alt_outlined, 'Gestión de usuarios', '/usuarios'),
    _ItemNav(Icons.person_add_alt_1_outlined, 'Registrar usuario', '/registrar'),
  ];

  @override
  void initState() {
    super.initState();
    NotificacionService.iniciar();
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  void _ir(String ruta) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    if (ruta == widget.ruta) return;
    if (ruta == '/registrar') {
      Navigator.pushNamed(context, ruta);
    } else {
      Navigator.pushReplacementNamed(context, ruta);
    }
  }

  void _buscarTexto(String texto) {
    final q = texto.trim();
    if (q.isEmpty) return;
    if (widget.ruta == '/buscar') {
      Navigator.pushReplacementNamed(context, '/buscar', arguments: q);
    } else {
      Navigator.pushNamed(context, '/buscar', arguments: q);
    }
  }

  Future<void> _cerrarSesion() async {
    await AuthService().cerrarSesion();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  Future<void> _verNotificaciones() async {
    if (!Session.logueado) {
      mostrarAviso('Inicia sesión para ver tus notificaciones');
      return;
    }
    final servicio = NotificacionService();
    final futuro = servicio.obtener().then((lista) {
      // Al abrir la campana, los avisos quedan como leídos.
      if (lista.any((n) => !n.leida)) servicio.marcarLeidas().catchError((_) {});
      return lista;
    });

    final idBlog = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notificaciones'),
        content: SizedBox(
          width: 400,
          child: FutureBuilder<List<NotificacionModel>>(
            future: futuro,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) return Text(snap.error.toString());
              final lista = snap.data ?? [];
              if (lista.isEmpty) {
                return const Text(
                  'Aún no tienes notificaciones. Aquí verás cuando comenten, '
                  'reaccionen o valoren tus publicaciones.',
                  style: TextStyle(color: Colores.textoSuave),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final n in lista)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onTap: n.blogId == null
                            ? null
                            : () => Navigator.pop(ctx, n.blogId),
                        leading: CircleAvatar(
                          radius: 17,
                          backgroundColor:
                              n.leida ? Colores.superficie2 : Colores.rojoOscuro,
                          child: Icon(_iconoTipo(n.tipo),
                              size: 17, color: Colors.white),
                        ),
                        title: Text(
                          n.texto,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight:
                                  n.leida ? FontWeight.w400 : FontWeight.w700,
                              fontSize: 13.5),
                        ),
                        subtitle: Text(
                          tiempoRelativo(n.fecha),
                          style: const TextStyle(
                              fontSize: 11, color: Colores.textoSuave),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await servicio.borrarTodas();
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Borrar todas'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (idBlog != null && mounted) {
      await abrirDetalleId(context, idBlog);
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'reaccion':
        return Icons.favorite_border_rounded;
      case 'valoracion':
        return Icons.star_border_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  void mostrarAviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Widget _campana() {
    return ValueListenableBuilder<int>(
      valueListenable: NotificacionService.noLeidas,
      builder: (context, n, _) => IconButton(
        tooltip: 'Notificaciones',
        onPressed: _verNotificaciones,
        icon: Badge(
          isLabelVisible: n > 0,
          label: Text(n > 99 ? '99+' : '$n'),
          backgroundColor: Colores.rojo,
          textColor: Colors.white,
          child: const Icon(Icons.notifications_none_rounded, size: 26),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final ancho = c.maxWidth >= 900;
      if (ancho) {
        return Scaffold(
          floatingActionButton: _botonNueva(),
          body: Row(
            children: [
              SizedBox(width: 244, child: _barraLateral()),
              const VerticalDivider(width: 1, color: Colores.borde),
              Expanded(
                child: Column(
                  children: [
                    _barraSuperior(compacta: false),
                    const Divider(height: 1, color: Colores.borde),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return Scaffold(
        drawer: Drawer(width: 270, child: _barraLateral()),
        floatingActionButton: _botonNueva(),
        appBar: AppBar(
          titleSpacing: 0,
          title: _logo(tamano: 22),
          actions: [_campana(), _avatar(), const SizedBox(width: 8)],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _campoBusqueda(),
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    });
  }

  // ---------- Piezas ----------

  Widget? _botonNueva() {
    if (!Session.logueado) return null;
    return FloatingActionButton.extended(
      onPressed: () => abrirFormulario(context),
      backgroundColor: Colores.rojo,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.edit_rounded),
      label: const Text('Nueva reseña'),
    );
  }

  Widget _logo({double tamano = 28}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.movie_filter_rounded, color: Colores.rojo, size: tamano + 6),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: tamano,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            children: const [
              TextSpan(text: 'Cine'),
              TextSpan(text: 'verse', style: TextStyle(color: Colores.rojo)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _campoBusqueda() {
    return TextField(
      controller: _buscar,
      textInputAction: TextInputAction.search,
      onSubmitted: _buscarTexto,
      decoration: InputDecoration(
        hintText: 'Buscar películas, series o artículos...',
        prefixIcon: const Icon(Icons.search_rounded),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        fillColor: Colores.superficie,
        suffixIcon: IconButton(
          tooltip: 'Buscar',
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          onPressed: () => _buscarTexto(_buscar.text),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colores.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colores.rojo, width: 1.4),
        ),
      ),
    );
  }

  Widget _avatar() {
    final usuario = Session.usuario;
    if (usuario == null) {
      return TextButton(
        onPressed: () =>
            Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false),
        child: const Text('Iniciar sesión'),
      );
    }
    return PopupMenuButton<String>(
      tooltip: usuario.nombre,
      color: Colores.superficie2,
      offset: const Offset(0, 46),
      onSelected: (valor) {
        if (valor == 'perfil') _ir('/perfil');
        if (valor == 'salir') _cerrarSesion();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(usuario.nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colores.texto)),
              Text(usuario.rol,
                  style: const TextStyle(
                      fontSize: 12, color: Colores.textoSuave)),
            ],
          ),
        ),
        const PopupMenuItem<String>(value: 'perfil', child: Text('Mi perfil')),
        const PopupMenuItem<String>(
            value: 'salir', child: Text('Cerrar sesión')),
      ],
      child: Avatar(texto: usuario.nombre, radio: 19),
    );
  }

  Widget _barraSuperior({required bool compacta}) {
    return Container(
      height: 76,
      color: Colores.fondo,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Align(alignment: Alignment.centerLeft, child: _campoBusqueda()),
          ),
          const SizedBox(width: 16),
          _campana(),
          const SizedBox(width: 8),
          _avatar(),
        ],
      ),
    );
  }

  Widget _barraLateral() {
    final logueado = Session.logueado;
    return Container(
      color: Colores.fondo,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 76,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _logo(tamano: 24),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  const SizedBox(height: 6),
                  for (final i in _principales) _entrada(i),
                  if (logueado) ...[
                    for (final i in _personales) _entrada(i),
                    const _Separador(),
                    for (final i in _cuenta) _entrada(i),
                    if (Session.esAdmin) ...[
                      const _Separador(),
                      for (final i in _admin) _entrada(i),
                    ],
                  ] else ...[
                    const _Separador(),
                    _entrada(const _ItemNav(
                        Icons.settings_outlined, 'Configuración', '/config')),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: logueado
                  ? OutlinedButton.icon(
                      onPressed: _cerrarSesion,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Cerrar sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colores.rojo,
                        side: const BorderSide(color: Colores.rojoOscuro),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (r) => false),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Iniciar sesión'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entrada(_ItemNav item) {
    final activa = item.ruta == widget.ruta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: activa
                ? const LinearGradient(
                    colors: [Colores.rojo, Colores.rojoOscuro],
                  )
                : null,
          ),
          child: ListTile(
            dense: true,
            minLeadingWidth: 24,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(item.icono,
                size: 22, color: activa ? Colors.white : Colores.textoSuave),
            title: Text(
              item.texto,
              style: TextStyle(
                fontSize: 15,
                fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
                color: activa ? Colors.white : Colores.texto,
              ),
            ),
            onTap: () => _ir(item.ruta),
          ),
        ),
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Divider(height: 1, color: Colores.borde),
    );
  }
}
