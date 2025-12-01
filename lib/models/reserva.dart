import 'package:cloud_firestore/cloud_firestore.dart';

  class Reserva {
  final String id;
  final String estudianteId;
  final String profesorId;
  final DateTime fecha;
  final int duracion; // en minutos
  final String modalidad; // 'online' o 'presencial'
  final String estado; // 'pendiente', 'confirmada', 'completada', 'cancelada'
  final double precio;
  final String? notasProfesor;
  final double? rating;
  final String? resena;

  Reserva({
    required this.id,
    required this.estudianteId,
    required this.profesorId,
    required this.fecha,
    required this.duracion,
    required this.modalidad,
    required this.estado,
    required this.precio,
    this.notasProfesor,
    this.rating,
    this.resena,
  });

  factory Reserva.fromMap(Map<String, dynamic> data) {
    final ts = data['fecha'];
    final fechaDt = ts is Timestamp ? ts.toDate() : DateTime.parse(ts);
    return Reserva(
      id: data['id'],
      estudianteId: data['estudianteId'],
      profesorId: data['profesorId'],
      fecha: fechaDt,
      duracion: data['duracion'],
      modalidad: data['modalidad'],
      estado: data['estado'],
      precio: data['precio'].toDouble(),
      notasProfesor: data['notasProfesor'],
      rating: data['rating']?.toDouble(),
      resena: data['reseña'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estudianteId': estudianteId,
      'profesorId': profesorId,
      'fecha': Timestamp.fromDate(fecha),
      'duracion': duracion,
      'modalidad': modalidad,
      'estado': estado,
      'precio': precio,
      'notasProfesor': notasProfesor,
      'rating': rating,
      'reseña': resena,
    };
  }
}

