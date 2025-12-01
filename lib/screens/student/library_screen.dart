import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/material.dart';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String get _estudianteId => _auth.usuario?.id ?? 'estudiante_id_placeholder';
  late final AuthService _auth;

  @override
  Widget build(BuildContext context) {
    _auth = Provider.of<AuthService>(context);
    final firestore = Provider.of<FirestoreService>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Biblioteca de Materiales')),
      body: StreamBuilder<List<MaterialEducativo>>(
        stream: firestore.obtenerMaterialesEstudiante(_estudianteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final materiales = snapshot.data ?? [];
          if (materiales.isEmpty) {
            return Center(
              child: Text(
                'No tienes materiales disponibles',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: materiales.length,
            itemBuilder: (context, index) {
              return _buildMaterialCard(materiales[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildMaterialCard(MaterialEducativo material) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          _getIconForType(material.tipo),
          color: Colors.blue,
          size: 40,
        ),
        title: Text(
          material.nombre,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profesor: ${material.profesorNombre}'),
            Text('Tipo: ${material.tipo} • ${material.tamano}'),
            Text(
              'Subido: ${DateFormat('dd/MM/yyyy').format(material.fechaSubida)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.download),
          onPressed: () => _descargarMaterial(material),
        ),
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.video_library;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _descargarMaterial(MaterialEducativo material) async {
    try {
      // Simular descarga
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Descargando...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Descargando ${material.nombre}'),
            ],
          ),
        ),
      );

      await Future.delayed(Duration(seconds: 2)); // Simular tiempo de descarga

      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${material.nombre} descargado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
