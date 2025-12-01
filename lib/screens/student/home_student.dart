import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/reserva.dart';
import '../../models/profesor.dart';
import 'package:intl/intl.dart';
import 'search_teachers.dart';
import 'progress_screen.dart';
import 'library_screen.dart';

class HomeStudentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MusiClase - Estudiante'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).cerrarSesion();
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildActionCard(
              context,
              'Buscar Profesores',
              Icons.search,
              Colors.blue,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchTeachersScreen())),
            ),
            _buildActionCard(
              context,
              'Mi Progreso',
              Icons.trending_up,
              Colors.green,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgressScreen())),
            ),
            _buildActionCard(
              context,
              'Biblioteca',
              Icons.library_books,
              Colors.orange,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => LibraryScreen())),
            ),
            SizedBox(height: 16),
            _buildMisClases(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 40),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMisClases(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final fs = Provider.of<FirestoreService>(context);
    final eid = auth.usuario?.id;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mis Clases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            if (eid == null)
              Text('Inicia sesión para ver tus clases')
            else
              StreamBuilder<List<Reserva>>(
                stream: fs.obtenerReservasEstudiante(eid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final reservas = snapshot.data ?? [];
                  if (reservas.isEmpty) {
                    return Text('No tienes reservas');
                  }
                  return Column(
                    children: reservas.take(5).map((r) => _ClaseTileEstudiante(reserva: r)).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ClaseTileEstudiante extends StatelessWidget {
  final Reserva reserva;
  const _ClaseTileEstudiante({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    return FutureBuilder<Profesor?>(
      future: fs.obtenerProfesor(reserva.profesorId),
      builder: (context, snapshot) {
        final nombre = snapshot.data?.nombre ?? reserva.profesorId;
        final esFuturo = reserva.fecha.isAfter(DateTime.now());
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange,
            child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?'),
          ),
          title: Text(nombre),
          subtitle: Text('Clase • ${DateFormat('dd/MM HH:mm').format(reserva.fecha)}'),
          trailing: Chip(
            label: Text(esFuturo ? 'Próxima' : 'Pasada'),
            backgroundColor: esFuturo ? Colors.green[100] : Colors.grey[300],
          ),
        );
      },
    );
  }
}
