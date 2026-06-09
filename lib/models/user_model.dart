class UserModel {
  final String uid;
  final String nombre;
  final String apellidos;
  final String correo;
  final String edad;
  final String username;
  final String rol; // 'user' | 'admin'

  UserModel({
    required this.uid,
    required this.nombre,
    required this.apellidos,
    required this.correo,
    required this.edad,
    required this.username,
    this.rol = 'user',
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nombre: map['nombre'] ?? '',
      apellidos: map['apellidos'] ?? '',
      correo: map['correo'] ?? '',
      edad: map['edad'] ?? '',
      username: map['username'] ?? '',
      rol: map['rol'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'apellidos': apellidos,
        'correo': correo,
        'edad': edad,
        'username': username,
        'rol': rol,
      };
}
