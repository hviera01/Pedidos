class Customer {
  final String id;
  final String nombre;
  final String telefono;
  final bool activo;

  const Customer({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.activo,
  });

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      id: id,
      nombre: (map['nombre'] ?? '').toString(),
      telefono: (map['telefono'] ?? '').toString(),
      activo: map['activo'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'activo': activo,
    };
  }
}