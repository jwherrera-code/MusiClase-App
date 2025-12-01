import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/profesor.dart';
import 'booking_screen.dart';

class SearchTeachersScreen extends StatefulWidget {
  @override
  _SearchTeachersScreenState createState() => _SearchTeachersScreenState();
}

class _SearchTeachersScreenState extends State<SearchTeachersScreen> {
  final List<String> instrumentos = ['Piano', 'Guitarra', 'Violín', 'Canto', 'Batería', 'Saxofón'];
  String? instrumentoSeleccionado;
  List<Profesor> profesores = [];

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Buscar Profesores')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: instrumentoSeleccionado,
              decoration: InputDecoration(
                labelText: 'Seleccionar Instrumento',
                border: OutlineInputBorder(),
              ),
              items: instrumentos.map((instrumento) {
                return DropdownMenuItem(
                  value: instrumento,
                  child: Text(instrumento),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  instrumentoSeleccionado = value;
                });
              },
            ),
          ),
          ElevatedButton(
            onPressed: instrumentoSeleccionado != null 
                ? () => _buscarProfesores(firestoreService)
                : null,
            child: Text('Buscar'),
          ),
          Expanded(
            child: StreamBuilder<List<Profesor>>(
              stream: firestoreService.obtenerProfesores(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ocurrió un error al cargar los profesores.'),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() {}),
                        child: Text('Reintentar'),
                      ),
                    ],
                  ));
                }
                
                List<Profesor> profesoresFiltrados = snapshot.data!.where((profesor) {
                  if (instrumentoSeleccionado == null) return true;
                  return profesor.instrumento == instrumentoSeleccionado;
                }).toList();
                
                return ListView.builder(
                  itemCount: profesoresFiltrados.length,
                  itemBuilder: (context, index) {
                    return _buildTeacherCard(profesoresFiltrados[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(Profesor profesor) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(profesor.nombre[0]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profesor.nombre,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(profesor.instrumento),
                      Text('Especialidad: ${profesor.especialidad}'),
                    ],
                  ),
                ),
                if (profesor.verificado)
                  Icon(Icons.verified, color: Colors.blue),
              ],
            ),
            SizedBox(height: 8),
            Text(profesor.descripcion),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${profesor.tarifaHora.toStringAsFixed(2)}/hora',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(profesor.rating.toStringAsFixed(1)),
                    Text(' (${profesor.totalClases} clases)'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(profesor: profesor),
                  ),
                );
              },
              child: Text('Reservar Clase'),
            ),
          ],
        ),
      ),
    );
  }

  void _buscarProfesores(FirestoreService firestoreService) async {
    if (instrumentoSeleccionado != null) {
      List<Profesor> resultados = await firestoreService.buscarProfesores(instrumentoSeleccionado!);
      setState(() {
        profesores = resultados;
      });
    }
  }
}
