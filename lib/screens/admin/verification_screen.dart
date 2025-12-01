import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TeacherVerification> _solicitudes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verificación de Profesores')),
      body: _solicitudes.isEmpty
          ? Center(
              child: Text(
                'No hay solicitudes pendientes',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _solicitudes.length,
              itemBuilder: (context, index) {
                return _buildVerificationCard(_solicitudes[index]);
              },
            ),
    );
  }

  Widget _buildVerificationCard(TeacherVerification solicitud) {
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
                  child: Text(solicitud.nombre[0]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.nombre,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(solicitud.instrumento),
                      Text('Experiencia: ${solicitud.experiencia}'),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    solicitud.estado == 'pendiente' ? 'Pendiente' : 'Verificado',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: solicitud.estado == 'pendiente' ? Colors.orange : Colors.green,
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Text(
              'Documentos presentados:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...solicitud.documentos.map((doc) => Text('• $doc')).toList(),
            
            SizedBox(height: 16),
            
            Text(
              'Solicitado: ${_formatDate(solicitud.fechaSolicitud)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            SizedBox(height: 16),
            
            if (solicitud.estado == 'pendiente')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _rechazarSolicitud(solicitud),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('Rechazar'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _aprobarSolicitud(solicitud),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text('Aprobar'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _aprobarSolicitud(TeacherVerification solicitud) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aprobar Solicitud'),
        content: Text('¿Estás seguro de aprobar la solicitud de ${solicitud.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                solicitud.estado = 'verificado';
              });
              Navigator.of(context).pop();
              _mostrarMensajeExito('Solicitud aprobada correctamente');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _rechazarSolicitud(TeacherVerification solicitud) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rechazar Solicitud'),
        content: Text('¿Estás seguro de rechazar la solicitud de ${solicitud.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _solicitudes.remove(solicitud);
              });
              Navigator.of(context).pop();
              _mostrarMensajeExito('Solicitud rechazada');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class TeacherVerification {
  final String id;
  final String nombre;
  final String email;
  final String instrumento;
  final String experiencia;
  final List<String> documentos;
  final DateTime fechaSolicitud;
  String estado; // 'pendiente', 'verificado', 'rechazado'

  TeacherVerification({
    required this.id,
    required this.nombre,
    required this.email,
    required this.instrumento,
    required this.experiencia,
    required this.documentos,
    required this.fechaSolicitud,
    required this.estado,
  });
}
