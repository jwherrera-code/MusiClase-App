class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String tipo; // 'estudiante', 'profesor', 'admin'
  final DateTime fechaRegistro;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.tipo,
    required this.fechaRegistro,
  });

  factory Usuario.fromMap(Map<String, dynamic> data) {
    return Usuario(
      id: data['id'],
      nombre: data['nombre'],
      email: data['email'],
      tipo: data['tipo'],
      fechaRegistro: DateTime.parse(data['fechaRegistro']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'tipo': tipo,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }
}