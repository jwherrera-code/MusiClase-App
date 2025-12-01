
import 'package:cloud_firestore/cloud_firestore.dart';
class MaterialEducativo {
  final String id;
  final String nombre;
  final String tipo; // 'pdf', 'audio', 'video', 'imagen'
  final String? descripcion;
  final String tamano;
  final String profesorId;
  final String profesorNombre;
  final DateTime fechaSubida;
  final List<String> compartidoCon; // lista de IDs de estudiantes

  MaterialEducativo({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    required this.tamano,
    required this.profesorId,
    required this.profesorNombre,
    required this.fechaSubida,
    required this.compartidoCon,
  });

  factory MaterialEducativo.fromMap(Map<String, dynamic> data) {
    final fs = data['fechaSubida'];
    final fecha = fs is Timestamp ? fs.toDate() : DateTime.parse(fs);
    return MaterialEducativo(
      id: data['id'],
      nombre: data['nombre'],
      tipo: data['tipo'],
      descripcion: data['descripcion'],
      tamano: data['tamano'],
      profesorId: data['profesorId'],
      profesorNombre: data['profesorNombre'],
      fechaSubida: fecha,
      compartidoCon: List<String>.from(data['compartidoCon'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'tamano': tamano,
      'profesorId': profesorId,
      'profesorNombre': profesorNombre,
      'fechaSubida': fechaSubida.toIso8601String(),
      'compartidoCon': compartidoCon,
    };
  }
}

