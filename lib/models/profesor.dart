class Profesor {
  final String id;
  final String usuarioId;
  final String nombre;
  final String especialidad;
  final String instrumento;
  final String descripcion;
  final double tarifaHora;
  final bool verificado;
  final double rating;
  final int totalClases;
  final List<String> modalidades; // ['online', 'presencial']

  Profesor({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.especialidad,
    required this.instrumento,
    required this.descripcion,
    required this.tarifaHora,
    required this.verificado,
    this.rating = 0.0,
    this.totalClases = 0,
    required this.modalidades,
  });

  factory Profesor.fromMap(Map<String, dynamic> data) {
    return Profesor(
      id: data['id'],
      usuarioId: data['usuarioId'],
      nombre: data['nombre'],
      especialidad: data['especialidad'],
      instrumento: data['instrumento'],
      descripcion: data['descripcion'],
      tarifaHora: data['tarifaHora'].toDouble(),
      verificado: data['verificado'],
      rating: data['rating']?.toDouble() ?? 0.0,
      totalClases: data['totalClases'] ?? 0,
      modalidades: List<String>.from(data['modalidades']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'nombre': nombre,
      'especialidad': especialidad,
      'instrumento': instrumento,
      'descripcion': descripcion,
      'tarifaHora': tarifaHora,
      'verificado': verificado,
      'rating': rating,
      'totalClases': totalClases,
      'modalidades': modalidades,
    };
  }
}