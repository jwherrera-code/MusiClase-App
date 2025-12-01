import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/usuario.dart';
import '../../models/profesor.dart';

class UserManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Gestión de Usuarios'),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            tabs: [
              Tab(text: 'Estudiantes'),
              Tab(text: 'Profesores'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: _buildEstudiantes(context, fs),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: _buildProfesores(context, fs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstudiantes(BuildContext context, FirestoreService fs) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estudiantes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Usuario>>(
                future: fs.listarEstudiantes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) return Text('Sin estudiantes');
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final u = list[i];
                      return ListTile(
                        leading: Icon(Icons.person),
                        title: Text(u.nombre),
                        subtitle: Text(u.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(Icons.edit), onPressed: () => _editarUsuario(context, fs, u)),
                            IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarUsuario(context, fs, u.id)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfesores(BuildContext context, FirestoreService fs) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profesores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Profesor>>(
                future: fs.listarProfesores(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) return Text('Sin profesores');
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final p = list[i];
                      return ListTile(
                        leading: Icon(Icons.school),
                        title: Text(p.nombre),
                        subtitle: Text(p.instrumento),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(Icons.edit), onPressed: () => _editarProfesor(context, fs, p)),
                            IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarProfesor(context, fs, p.id)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarUsuario(BuildContext context, FirestoreService fs, Usuario u) async {
    final nombreCtrl = TextEditingController(text: u.nombre);
    final emailCtrl = TextEditingController(text: u.email);
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Estudiante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: InputDecoration(labelText: 'Nombre')),
            SizedBox(height: 8),
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop({'nombre': nombreCtrl.text, 'email': emailCtrl.text}), child: Text('Guardar')),
        ],
      ),
    );
    if (res != null) {
      final actualizado = Usuario(id: u.id, nombre: res['nombre'] ?? u.nombre, email: res['email'] ?? u.email, tipo: u.tipo, fechaRegistro: u.fechaRegistro);
      await fs.guardarUsuario(actualizado);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estudiante actualizado'), backgroundColor: Colors.green));
    }
  }

  Future<void> _eliminarUsuario(BuildContext context, FirestoreService fs, String id) async {
    await fs.eliminarUsuario(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estudiante eliminado'), backgroundColor: Colors.green));
  }

  Future<void> _editarProfesor(BuildContext context, FirestoreService fs, Profesor p) async {
    final nombreCtrl = TextEditingController(text: p.nombre);
    final instrumentoCtrl = TextEditingController(text: p.instrumento);
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Profesor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: InputDecoration(labelText: 'Nombre')),
            SizedBox(height: 8),
            TextField(controller: instrumentoCtrl, decoration: InputDecoration(labelText: 'Instrumento')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop({'nombre': nombreCtrl.text, 'instrumento': instrumentoCtrl.text}), child: Text('Guardar')),
        ],
      ),
    );
    if (res != null) {
      final actualizado = Profesor(
        id: p.id,
        usuarioId: p.usuarioId,
        nombre: res['nombre'] ?? p.nombre,
        especialidad: p.especialidad,
        instrumento: res['instrumento'] ?? p.instrumento,
        descripcion: p.descripcion,
        tarifaHora: p.tarifaHora,
        verificado: p.verificado,
        rating: p.rating,
        totalClases: p.totalClases,
        modalidades: p.modalidades,
      );
      await fs.guardarProfesor(actualizado);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profesor actualizado'), backgroundColor: Colors.green));
    }
  }

  Future<void> _eliminarProfesor(BuildContext context, FirestoreService fs, String id) async {
    await fs.eliminarProfesor(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profesor eliminado'), backgroundColor: Colors.green));
  }
}
