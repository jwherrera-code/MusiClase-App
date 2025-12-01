import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'availability_screen.dart';
import 'materials_screen.dart';
import '../../models/reserva.dart';
import '../../models/usuario.dart';

class HomeTeacherScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MusiClase - Profesor'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel del Profesor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            // Estadísticas rápidas
            _buildStatsRow(context),
            SizedBox(height: 20),
            
            // Acciones rápidas
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    'Disponibilidad',
                    Icons.calendar_today,
                    Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => AvailabilityScreen())),
                  ),
                  _buildActionCard(
                    'Materiales',
                    Icons.library_books,
                    Colors.green,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialsScreen())),
                  ),
                  _buildActionCard(
                    'Reservas',
                    Icons.book_online,
                    Colors.orange,
                    () => _verReservas(context),
                  ),
                ],
              ),
            ),
            
            // Próximas clases
            _buildNextClasses(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final fs = Provider.of<FirestoreService>(context);
    final pid = auth.usuario?.id;
    if (pid == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Clases\nesta semana', '—', Colors.blue),
        ],
      );
    }
    return FutureBuilder<int>(
      future: fs.contarReservasProfesorSemana(pid),
      builder: (context, snapshot) {
        final clases = snapshot.data;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Clases\nesta semana', clases?.toString() ?? '—', Colors.blue),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextClasses(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final fs = Provider.of<FirestoreService>(context);
    final profesorId = auth.usuario?.id;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Próximas Clases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            if (profesorId == null)
              Text('Inicia sesión para ver tus próximas clases')
            else
              StreamBuilder(
                stream: fs.obtenerReservasProfesor(profesorId),
                builder: (context, AsyncSnapshot<List<Reserva>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final reservas = snapshot.data?.where((r) => r.fecha.isAfter(DateTime.now())).toList() ?? [];
                  if (reservas.isEmpty) {
                    return Text('No tienes clases próximas');
                  }
                  return Column(
                    children: reservas.take(5).map((r) => _AlumnoTile(reserva: r)).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _verReservas(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final pid = auth.usuario?.id;
    if (pid == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Reservas'),
          content: Text('Inicia sesión para ver tus reservas'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK'))],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reservas del Profesor'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Reserva>>(
            stream: fs.obtenerReservasProfesor(pid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final reservas = snapshot.data ?? [];
              if (reservas.isEmpty) {
                return Text('No hay reservas');
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: reservas.length,
                itemBuilder: (context, i) => _AlumnoTile(reserva: reservas[i]),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cerrar'))],
      ),
    );
  }

}

class _AlumnoTile extends StatelessWidget {
  final Reserva reserva;
  const _AlumnoTile({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    return FutureBuilder<Usuario>(
      future: fs.obtenerUsuario(reserva.estudianteId),
      builder: (context, snapshot) {
        final nombre = snapshot.data?.nombre ?? reserva.estudianteId;
        final esFuturo = reserva.fecha.isAfter(DateTime.now());
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue,
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
