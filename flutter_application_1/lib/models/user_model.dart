class UserModel {
  final int id;
  final String nombre;
  final String correo;
  final String? password;
  final String? direccion;
  final int tipoUsuario;

  UserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    this.password,
    this.direccion,
    this.tipoUsuario = 2,
  });

  bool get esAdmin => tipoUsuario == 1;
  String get rol => esAdmin ? 'Administrador' : 'Usuario';

  /// Nombre para mostrar como "@usuario".
  String get alias => '@${nombre.replaceAll(' ', '').toLowerCase()}';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id_usr'] as int,
      nombre: json['nom_usr'] as String,
      correo: json['mail'] as String,
      direccion: json['dir_usr'] as String?,
      tipoUsuario: (json['tip_usu'] as num?)?.toInt() ?? 2,
    );
  }

  Map<String, dynamic> toJsonCrear() {
    return {
      'nom_usr': nombre,
      'mail': correo,
      'password': password,
      'dir_usr': direccion,
      'tip_usu': tipoUsuario,
    };
  }
}
