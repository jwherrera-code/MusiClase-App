import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/material.dart';
import '../../models/usuario.dart';

class MaterialsScreen extends StatefulWidget {
  @override
  _MaterialsScreenState createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final List<MaterialEducativo> _materiales = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Materiales Educativos')),
      floatingActionButton: FloatingActionButton(
        onPressed: _subirMaterial,
        child: Icon(Icons.add),
      ),
      body: Consumer2<AuthService, FirestoreService>(
        builder: (context, auth, fs, _) {
          final uid = auth.usuario?.id;
          if (uid == null) {
            return Center(child: Text('Inicia sesión como profesor'));
          }
          return StreamBuilder<List<MaterialEducativo>>(
            stream: fs.obtenerMaterialesProfesor(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final materiales = snapshot.data ?? [];
              if (materiales.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay materiales subidos', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Presiona el botón + para agregar materiales', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: materiales.length,
                itemBuilder: (context, index) => _buildMaterialItem(materiales[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMaterialItem(MaterialEducativo material) {
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
            Text('Tipo: ${material.tipo} • ${material.tamano}'),
            Text(
              'Subido: ${DateFormat('dd/MM/yyyy').format(material.fechaSubida)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (material.descripcion != null)
              Text(
                material.descripcion!,
                style: TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Text('Compartir con alumnos'),
              value: 'compartir',
            ),
            PopupMenuItem(
              child: Text('Eliminar'),
              value: 'eliminar',
            ),
          ],
          onSelected: (value) {
            if (value == 'eliminar') {
              _eliminarMaterial(material);
            } else if (value == 'compartir') {
              _compartirMaterial(material);
            }
          },
        ),
      ),
    );
  }

  Future<void> _subirMaterial() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UploadMaterialDialog(),
    );

    if (result != null) {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.usuario;
      if (user == null || user.tipo != 'profesor') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debes iniciar sesión como profesor para subir materiales'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final nuevo = MaterialEducativo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: result['nombre'],
        tipo: (result['tipo'] as String).toLowerCase(),
        descripcion: result['descripcion'],
        tamano: '2.5 MB',
        profesorId: user.id,
        profesorNombre: user.nombre,
        fechaSubida: DateTime.now(),
        compartidoCon: [],
      );

      try {
        await firestore.subirMaterial(nuevo);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Material subido correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de permisos al subir material'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _eliminarMaterial(MaterialEducativo material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Material'),
        content: Text('¿Estás seguro de eliminar "${material.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final fs = Provider.of<FirestoreService>(context, listen: false);
              fs.eliminarMaterial(material.id).then((_) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Material eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
              }).catchError((_) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo eliminar el material'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _compartirMaterial(MaterialEducativo material) async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.usuario?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes iniciar sesión para compartir'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final seleccionado = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecciona alumno'),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<Usuario>>(
              future: Provider.of<FirestoreService>(context, listen: false).listarEstudiantes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final alumnos = snapshot.data ?? [];
                if (alumnos.isEmpty) {
                  return Text('No hay alumnos disponibles');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: alumnos.length,
                  itemBuilder: (context, i) {
                    final a = alumnos[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(a.nombre.isNotEmpty ? a.nombre[0].toUpperCase() : '?')),
                      title: Text(a.nombre),
                      subtitle: Text(a.id),
                      onTap: () => Navigator.of(context).pop(a.id),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancelar')),
          ],
        );
      },
    );

    if (seleccionado == null) return;

    await firestore.compartirMaterialConEstudiante(material.id, seleccionado);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${material.nombre}" compartido con ${seleccionado}'),
        backgroundColor: Colors.blue,
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
      case 'imagen':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}

// Usar MaterialEducativo del modelo

class UploadMaterialDialog extends StatefulWidget {
  @override
  _UploadMaterialDialogState createState() => _UploadMaterialDialogState();
}

class _UploadMaterialDialogState extends State<UploadMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _tipoSeleccionado = 'PDF';
  final List<String> _tipos = ['PDF', 'Audio', 'Video', 'Imagen'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Subir Material'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre del material'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              decoration: InputDecoration(labelText: 'Tipo de archivo'),
              items: _tipos.map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoSeleccionado = value!;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: InputDecoration(labelText: 'Descripción (opcional)'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _seleccionarArchivo,
              child: Text('Seleccionar Archivo (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _subirArchivo,
          child: Text('Guardar'),
        ),
      ],
    );
  }

  void _seleccionarArchivo() async {
    if (_nombreController.text.isEmpty) {
      _nombreController.text = 'archivo_simulado.pdf';
    }
  }

  void _subirArchivo() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'nombre': _nombreController.text,
        'tipo': _tipoSeleccionado,
        'descripcion': _descripcionController.text.isEmpty 
            ? null 
            : _descripcionController.text,
      });
    }
  }
}
