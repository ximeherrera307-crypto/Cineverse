import 'package:flutter/material.dart';

import 'core/api.dart';
import 'core/theme.dart';
import 'screens/home_page.dart';
import 'screens/listado_page.dart';
import 'screens/login_user_page.dart';
import 'screens/profile_page.dart';
import 'screens/recuperar_contrasena_page.dart';
import 'screens/register_user_page.dart';
import 'screens/settings_page.dart';
import 'screens/users_page.dart';

void main() {
  runApp(const CineverseApp());
}

class CineverseApp extends StatelessWidget {
  const CineverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cineverse',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: construirTema(),
      initialRoute: '/login',
      onGenerateRoute: _rutas,
    );
  }

  static Route<dynamic> _rutas(RouteSettings s) {
    Widget pagina;
    switch (s.name) {
      case '/login':
        pagina = const LoginPage();
      case '/registrar':
        pagina = const RegisterPage();
      case '/recuperar':
        pagina = const RecoverPasswordPage();
      case '/home':
        pagina = const HomePage();
      case '/peliculas':
        pagina = const ListadoPage(
            key: ValueKey('peliculas'),
            ruta: '/peliculas', titulo: 'Películas', tipo: 'pelicula');
      case '/series':
        pagina = const ListadoPage(
            key: ValueKey('series'),
            ruta: '/series', titulo: 'Series', tipo: 'serie');
      case '/articulos':
        pagina = const ListadoPage(
            key: ValueKey('articulos'),
            ruta: '/articulos', titulo: 'Artículos', tipo: 'articulo');
      case '/mis-resenas':
        pagina = const ListadoPage(
            key: ValueKey('mias'),
            ruta: '/mis-resenas', titulo: 'Mis reseñas', mias: true);
      case '/guardados':
        pagina = const ListadoPage(
            key: ValueKey('guardados'),
            ruta: '/guardados', titulo: 'Guardados', guardados: true);
      case '/buscar':
        final q = (s.arguments as String?) ?? '';
        pagina = ListadoPage(
            key: ValueKey('buscar-$q'),
            ruta: '/buscar', titulo: 'Búsqueda', consulta: q);
      case '/perfil':
        pagina = const ProfilePage();
      case '/config':
        pagina = const SettingsPage();
      case '/usuarios':
        pagina = const UsersPage();
      default:
        pagina = const LoginPage();
    }
    return MaterialPageRoute(settings: s, builder: (_) => pagina);
  }
}
