class AppUser {
  final String codigo;
  final String nombre;
  final String rol;
  final bool activo;

  const AppUser({
    required this.codigo,
    required this.nombre,
    required this.rol,
    required this.activo,
  });

  factory AppUser.fromMap(String codigo, Map<String, dynamic> map) {
    return AppUser(
      codigo: codigo,
      nombre: (map['nombre'] ?? 'Usuario').toString(),
      rol: (map['rol'] ?? 'operador').toString().toLowerCase(),
      activo: map['activo'] != false,
    );
  }

  Map<String, dynamic> toSessionMap() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'rol': rol,
      'activo': activo,
    };
  }

  factory AppUser.fromSessionMap(Map<String, dynamic> map) {
    return AppUser(
      codigo: (map['codigo'] ?? '').toString(),
      nombre: (map['nombre'] ?? 'Usuario').toString(),
      rol: (map['rol'] ?? 'operador').toString().toLowerCase(),
      activo: map['activo'] != false,
    );
  }

  bool get isAdmin => rol == 'admin';
  bool get isPublico => rol == 'publico';
}