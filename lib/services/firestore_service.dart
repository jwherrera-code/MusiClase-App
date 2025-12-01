import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';
import '../models/profesor.dart';
import '../models/reserva.dart';
import '../models/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Usuarios
  Future<void> guardarUsuario(Usuario usuario) async {
    await _firestore.collection('usuarios').doc(usuario.id).set(usuario.toMap());
  }

  Future<Usuario> obtenerUsuario(String id) async {
    DocumentSnapshot doc = await _firestore.collection('usuarios').doc(id).get();
    return Usuario.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Profesores
  Future<void> guardarProfesor(Profesor profesor) async {
    await _firestore.collection('profesores').doc(profesor.id).set(profesor.toMap());
  }

  Future<void> actualizarProfesorTarifa(String profesorId, double tarifaHora) async {
    await _firestore.collection('profesores').doc(profesorId).update({'tarifaHora': tarifaHora});
  }

  Stream<List<Profesor>> obtenerProfesores() {
    return _firestore.collection('profesores').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Profesor.fromMap(doc.data())).toList();
    });
  }

  Future<List<Profesor>> buscarProfesores(String instrumento) async {
    QuerySnapshot snapshot = await _firestore
        .collection('profesores')
        .where('instrumento', isEqualTo: instrumento)
        .get();
    
    return snapshot.docs.map((doc) => Profesor.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<Profesor?> obtenerProfesor(String id) async {
    final doc = await _firestore.collection('profesores').doc(id).get();
    if (!doc.exists) return null;
    return Profesor.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<int> contarUsuarios() async {
    final qs = await _firestore.collection('usuarios').get();
    return qs.size;
  }

  Future<int> contarEstudiantes() async {
    final qs = await _firestore.collection('usuarios').where('tipo', isEqualTo: 'estudiante').get();
    return qs.size;
  }

  Future<int> contarProfesores() async {
    final qs = await _firestore.collection('profesores').get();
    return qs.size;
  }

  Future<int> contarReservasHoy() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(Duration(days: 1));
    final qs = await _firestore
        .collection('reservas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fecha', isLessThan: Timestamp.fromDate(end))
        .get();
    return qs.size;
  }

  Future<double> ingresosMesActual() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final qs = await _firestore
        .collection('reservas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fecha', isLessThan: Timestamp.fromDate(end))
        .get();
    double total = 0.0;
    for (final d in qs.docs) {
      final data = d.data() as Map<String, dynamic>;
      final precio = (data['precio'] as num?)?.toDouble() ?? 0.0;
      total += precio;
    }
    return total;
  }

  Future<int> contarReservasProfesorSemana(String profesorId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    final end = start.add(Duration(days: 7));
    final qs = await _firestore
        .collection('reservas')
        .where('profesorId', isEqualTo: profesorId)
        .get();
    int count = 0;
    for (final d in qs.docs) {
      final data = d.data() as Map<String, dynamic>;
      final f = data['fecha'];
      final dt = f is Timestamp ? f.toDate() : DateTime.parse(f);
      if (!dt.isBefore(start) && dt.isBefore(end)) {
        count++;
      }
    }
    return count;
  }

  Future<double> ingresosProfesorMes(String profesorId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final qs = await _firestore
        .collection('reservas')
        .where('profesorId', isEqualTo: profesorId)
        .get();
    double total = 0.0;
    for (final d in qs.docs) {
      final data = d.data() as Map<String, dynamic>;
      final f = data['fecha'];
      final dt = f is Timestamp ? f.toDate() : DateTime.parse(f);
      if (!dt.isBefore(start) && dt.isBefore(end)) {
        total += (data['precio'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  Future<List<Usuario>> listarEstudiantes() async {
    final qs = await _firestore.collection('usuarios').where('tipo', isEqualTo: 'estudiante').get();
    return qs.docs.map((d) => Usuario.fromMap(d.data() as Map<String, dynamic>)).toList();
  }

  Future<List<Profesor>> listarProfesores() async {
    final qs = await _firestore.collection('profesores').get();
    return qs.docs.map((d) => Profesor.fromMap(d.data() as Map<String, dynamic>)).toList();
  }

  Future<void> eliminarUsuario(String usuarioId) async {
    await _firestore.collection('usuarios').doc(usuarioId).delete();
  }

  Future<void> eliminarProfesor(String profesorId) async {
    await _firestore.collection('profesores').doc(profesorId).delete();
  }

  // Reservas
  Future<void> crearReserva(Reserva reserva) async {
    await _firestore.collection('reservas').doc(reserva.id).set(reserva.toMap());
    final inicio = reserva.fecha;
    final fin = inicio.add(Duration(minutes: reserva.duracion));
    await _firestore.collection('ocupaciones').doc(reserva.id).set({
      'reservaId': reserva.id,
      'profesorId': reserva.profesorId,
      'inicio': Timestamp.fromDate(inicio),
      'fin': Timestamp.fromDate(fin),
      'activa': true,
    });
  }

  Stream<List<Reserva>> obtenerReservasEstudiante(String estudianteId) {
    return _firestore
        .collection('reservas')
        .where('estudianteId', isEqualTo: estudianteId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Reserva.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => b.fecha.compareTo(a.fecha));
          return list;
        });
  }

  Stream<List<Reserva>> obtenerReservasProfesor(String profesorId) {
    return _firestore
        .collection('reservas')
        .where('profesorId', isEqualTo: profesorId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Reserva.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => a.fecha.compareTo(b.fecha));
          return list;
        });
  }

  Future<void> actualizarReserva(String reservaId, Map<String, dynamic> datos) async {
    await _firestore.collection('reservas').doc(reservaId).update(datos);
    if (datos.containsKey('estado') && datos['estado'] == 'cancelada') {
      await _firestore.collection('ocupaciones').doc(reservaId).update({'activa': false});
    }
  }

  Future<List<Reserva>> listarReservasMesActual() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final qs = await _firestore
        .collection('reservas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fecha', isLessThan: Timestamp.fromDate(end))
        .get();
    return qs.docs.map((d) => Reserva.fromMap(d.data() as Map<String, dynamic>)).toList();
  }

  // Materiales
  Future<void> subirMaterial(MaterialEducativo material) async {
    final docRef = _firestore.collection('materiales').doc();
    final data = material.toMap();
    data['id'] = docRef.id;
    await docRef.set(data);
  }

  Future<void> eliminarMaterial(String materialId) async {
    await _firestore.collection('materiales').doc(materialId).delete();
  }

  Stream<List<MaterialEducativo>> obtenerMaterialesEstudiante(String estudianteId) {
    return _firestore
        .collection('materiales')
        .where('compartidoCon', arrayContains: estudianteId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => MaterialEducativo.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => b.fechaSubida.compareTo(a.fechaSubida));
          return list;
        });
  }

  Stream<List<MaterialEducativo>> obtenerMaterialesProfesor(String profesorId) {
    return _firestore
        .collection('materiales')
        .where('profesorId', isEqualTo: profesorId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => MaterialEducativo.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => b.fechaSubida.compareTo(a.fechaSubida));
          return list;
        });
  }

  Future<void> compartirMaterialConEstudiante(String materialId, String estudianteId) async {
    final docRef = _firestore.collection('materiales').doc(materialId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> compartido = (data['compartidoCon'] ?? []);
      if (!compartido.contains(estudianteId)) {
        compartido.add(estudianteId);
      }
      txn.update(docRef, {'compartidoCon': compartido});
    });
  }

  // Disponibilidad de profesor
  Future<void> guardarDisponibilidad(String profesorId, double tarifaHora, Map<String, List<Map<String, String>>> slotsPorDia) async {
    await _firestore.collection('disponibilidad').doc(profesorId).set({
      'tarifaHora': tarifaHora,
      'slots': slotsPorDia,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> obtenerDisponibilidad(String profesorId) async {
    final snap = await _firestore.collection('disponibilidad').doc(profesorId).get();
    if (!snap.exists) return null;
    return snap.data() as Map<String, dynamic>;
  }

  Future<bool> verificarDisponibilidad(String profesorId, DateTime inicio, int duracionMin) async {
    final disp = await obtenerDisponibilidad(profesorId);
    if (disp == null) return false;
    final slots = disp['slots'] as Map<String, dynamic>?;
    if (slots == null) return false;

    final diaSemana = _diaSemanaES(inicio.weekday);
    final listaSlots = (slots[diaSemana] as List<dynamic>? ?? [])
        .map((e) => {'inicio': e['inicio'] as String, 'fin': e['fin'] as String})
        .toList();

    bool dentroDeSlot = false;
    final finPropuesto = inicio.add(Duration(minutes: duracionMin));

    DateTime _parseHora(String hhmm, DateTime base) {
      final parts = hhmm.split(":");
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return DateTime(base.year, base.month, base.day, h, m);
    }

    for (final s in listaSlots) {
      final si = s['inicio']!;
      final sf = s['fin']!;
      final slotInicio = _parseHora(si, inicio);
      final slotFin = _parseHora(sf, inicio);
      if (!finPropuesto.isAfter(slotFin)) {
        if (!inicio.isBefore(slotInicio)) {
          dentroDeSlot = true;
          break;
        }
      }
    }
    if (!dentroDeSlot) return false;

    final diaInicio = DateTime(inicio.year, inicio.month, inicio.day);
    final diaFin = diaInicio.add(Duration(days: 1));
    final qs = await _firestore
        .collection('ocupaciones')
        .where('profesorId', isEqualTo: profesorId)
        .where('inicio', isGreaterThanOrEqualTo: Timestamp.fromDate(diaInicio))
        .where('inicio', isLessThan: Timestamp.fromDate(diaFin))
        .where('activa', isEqualTo: true)
        .get();

    final proposedStart = inicio;
    final proposedEnd = finPropuesto;
    for (final d in qs.docs) {
      final data = d.data() as Map<String, dynamic>;
      final start = (data['inicio'] as Timestamp).toDate();
      final existingEnd = (data['fin'] as Timestamp).toDate();
      final overlap = proposedStart.isBefore(existingEnd) && proposedEnd.isAfter(start);
      if (overlap) return false;
    }
    return true;
  }

  Future<List<DateTime>> obtenerSlotsDisponibles(String profesorId, DateTime dia, int duracionMin) async {
    final disp = await obtenerDisponibilidad(profesorId);
    if (disp == null) return [];
    final slots = disp['slots'] as Map<String, dynamic>?;
    if (slots == null) return [];

    final diaSemana = _diaSemanaES(dia.weekday);
    final listaSlots = (slots[diaSemana] as List<dynamic>? ?? [])
        .map((e) => {'inicio': e['inicio'] as String, 'fin': e['fin'] as String})
        .toList();

    DateTime _parseHora(String hhmm, DateTime base) {
      final parts = hhmm.split(":");
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return DateTime(base.year, base.month, base.day, h, m);
    }

    final inicioDia = DateTime(dia.year, dia.month, dia.day);
    final finDia = inicioDia.add(Duration(days: 1));
    final ocupQS = await _firestore
        .collection('ocupaciones')
        .where('profesorId', isEqualTo: profesorId)
        .where('inicio', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('inicio', isLessThan: Timestamp.fromDate(finDia))
        .where('activa', isEqualTo: true)
        .get();
    final reservas = ocupQS.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      final start = (data['inicio'] as Timestamp).toDate();
      final end = (data['fin'] as Timestamp).toDate();
      return {'inicio': start, 'fin': end};
    }).toList();

    final List<DateTime> disponibles = [];
    for (int h = 9; h <= 16; h++) {
      final candidate = DateTime(dia.year, dia.month, dia.day, h, 0);
      final candidateEnd = candidate.add(Duration(minutes: duracionMin));

      bool dentro = false;
      for (final s in listaSlots) {
        final si = _parseHora(s['inicio']!, dia);
        final sf = _parseHora(s['fin']!, dia);
        if (!candidateEnd.isAfter(sf) && !candidate.isBefore(si)) {
          dentro = true;
          break;
        }
      }
      if (!dentro) continue;

      bool solapa = false;
      for (final r in reservas) {
        final rs = r['inicio'] as DateTime;
        final re = r['fin'] as DateTime;
        final overlap = candidate.isBefore(re) && candidateEnd.isAfter(rs);
        if (overlap) {
          solapa = true;
          break;
        }
      }
      if (!solapa) disponibles.add(candidate);
    }
    return disponibles;
  }

  String _diaSemanaES(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lunes';
      case DateTime.tuesday:
        return 'Martes';
      case DateTime.wednesday:
        return 'Miércoles';
      case DateTime.thursday:
        return 'Jueves';
      case DateTime.friday:
        return 'Viernes';
      case DateTime.saturday:
        return 'Sábado';
      default:
        return 'Domingo';
    }
  }

  String _formatHora(DateTime dt) {
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }
}
