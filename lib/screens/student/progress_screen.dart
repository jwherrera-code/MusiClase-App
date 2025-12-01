import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/reserva.dart';

class ProgressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final auth = Provider.of<AuthService>(context);
    final String? estudianteId = auth.usuario?.id;

    return Scaffold(
      appBar: AppBar(title: Text('Mi Progreso')),
      body: estudianteId == null
          ? Center(child: Text('Inicia sesión para ver tu progreso'))
          : StreamBuilder<List<Reserva>>(
        stream: firestoreService.obtenerReservasEstudiante(estudianteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el progreso'));
          }

          final reservas = snapshot.data ?? [];
          final clasesCompletadas = reservas.where((r) => r.estado == 'completada').toList();
          final clasesPendientes = reservas.where((r) => r.estado == 'confirmada').toList();
          final total = clasesCompletadas.length + clasesPendientes.length;

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estadísticas rápidas
                _buildStatsCard(clasesCompletadas.length, clasesPendientes.length),
                SizedBox(height: 12),
                _buildProgressBar(clasesCompletadas.length, total),
                SizedBox(height: 20),
                
                // Historial de clases
                Text(
                  'Historial de Clases',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: clasesCompletadas.length,
                    itemBuilder: (context, index) {
                      return _buildClassHistoryCard(context, clasesCompletadas[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(int completadas, int total) {
    final value = total == 0 ? 0.0 : completadas / total;
    final etiqueta = 'Actual ${completadas} de ${total}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        LinearProgressIndicator(value: value),
      ],
    );
  }

  Widget _buildStatsCard(int completadas, int pendientes) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Completadas', completadas, Colors.green),
            _buildStatItem('Pendientes', pendientes, Colors.orange),
            _buildStatItem('Total', completadas + pendientes, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildClassHistoryCard(BuildContext context, Reserva reserva) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy - HH:mm').format(reserva.fecha),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(reserva.modalidad),
                  backgroundColor: reserva.modalidad == 'online' 
                      ? Colors.blue[100] 
                      : Colors.green[100],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (reserva.notasProfesor != null) ...[
              Text(
                'Notas del profesor:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(reserva.notasProfesor!),
              SizedBox(height: 8),
            ],
            if (reserva.rating != null) ...[
              Row(
                children: [
                  Text('Tu calificación: '),
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  Text(reserva.rating!.toStringAsFixed(1)),
                ],
              ),
            ] else if (reserva.estado == 'completada') ...[
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _valorarReserva(context, reserva),
                child: Text('Valorar al profesor'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _valorarReserva(BuildContext context, Reserva reserva) async {
    double _rating = 5.0;
    final TextEditingController _resenaController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Valorar Clase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 5,
                    divisions: 8,
                    value: _rating,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (v) {
                      _rating = v;
                    },
                  ),
                ),
              ],
            ),
            TextField(
              controller: _resenaController,
              decoration: InputDecoration(labelText: 'Reseña (opcional)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop({
                'rating': _rating,
                'reseña': _resenaController.text.isEmpty ? null : _resenaController.text,
              });
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      await firestore.actualizarReserva(reserva.id, {
        'rating': result['rating'],
        'reseña': result['reseña'],
      });
    }
  }
}
