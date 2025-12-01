class Clase {
  final String id;
  final String reservaId;
  final String profesorId;
  final String estudianteId;
  final DateTime fecha;
  final int duracion;
  final String estado; // 'programada', 'completada', 'cancelada'
  final String? notasProfesor;

  Clase({
    required this.id,
    required this.reservaId,
    required this.profesorId,
    required this.estudianteId,
    required this.fecha,
    required this.duracion,
    required this.estado,
    this.notasProfesor,
  });

  factory Clase.fromMap(Map<String, dynamic> data) {
    return Clase(
      id: data['id'],
      reservaId: data['reservaId'],
      profesorId: data['profesorId'],
      estudianteId: data['estudianteId'],
      fecha: DateTime.parse(data['fecha']),
      duracion: data['duracion'],
      estado: data['estado'],
      notasProfesor: data['notasProfesor'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reservaId': reservaId,
      'profesorId': profesorId,
      'estudianteId': estudianteId,
      'fecha': fecha.toIso8601String(),
      'duracion': duracion,
      'estado': estado,
      'notasProfesor': notasProfesor,
    };
  }
}
