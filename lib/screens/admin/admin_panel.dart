import 'package:flutter/material.dart';
import 'package:musiclase_app/models/reserva.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/usuario.dart';
import '../../models/profesor.dart';
import 'user_management.dart';

class AdminPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Administración'),
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
              'Dashboard Administrativo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Consumer<FirestoreService>(
              builder: (context, fs, _) {
                return FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    fs.contarEstudiantes(),
                    fs.contarProfesores(),
                    fs.contarReservasHoy(),
                    fs.ingresosMesActual(),
                  ]),
                  builder: (context, snapshot) {
                    final usuarios = snapshot.hasData ? snapshot.data![0] as int : null;
                    final profesores = snapshot.hasData ? snapshot.data![1] as int : null;
                    final clasesHoy = snapshot.hasData ? snapshot.data![2] as int : null;
                    final ingresosMes = snapshot.hasData ? snapshot.data![3] as double : null;
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildMetricCard('Estudiantes', usuarios?.toString() ?? '—', Icons.people, Colors.blue, onTap: () => _mostrarListaEstudiantes(context)),
                        _buildMetricCard('Profesores', profesores?.toString() ?? '—', Icons.school, Colors.green, onTap: () => _mostrarListaProfesores(context)),
                        _buildMetricCard('Clases Hoy', clasesHoy?.toString() ?? '—', Icons.calendar_today, Colors.orange),
                        _buildMetricCard('Ingresos Mes', ingresosMes != null ? '\$${ingresosMes.toStringAsFixed(2)}' : '—', Icons.attach_money, Colors.purple),
                      ],
                    );
                  },
                );
              },
            ),
            
            SizedBox(height: 20),
            
            // Acciones rápidas
            Expanded(
              child: ListView(
                children: [
                  _buildActionTile(
                    'Reportes de Reservas',
                    Icons.bar_chart,
                    Colors.green,
                    () => _verReportes(context),
                  ),
                  _buildActionTile(
                    'Gestión de Usuarios',
                    Icons.manage_accounts,
                    Colors.orange,
                    () => _gestionarUsuarios(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarListaEstudiantes(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Estudiantes'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Usuario>>( 
            future: fs.listarEstudiantes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Text('No hay estudiantes');
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final u = items[i];
                  return ListTile(
                    leading: Icon(Icons.person),
                    title: Text(u.nombre),
                    subtitle: Text(u.email),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cerrar')),
        ],
      ),
    );
  }

  void _mostrarListaProfesores(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profesores'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Profesor>>( 
            future: fs.listarProfesores(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Text('No hay profesores');
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final p = items[i];
                  return ListTile(
                    leading: Icon(Icons.school),
                    title: Text(p.nombre),
                    subtitle: Text(p.instrumento),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  

  void _verReportes(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reportes de Reservas'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([
              fs.listarReservasMesActual(),
              fs.ingresosMesActual(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final reservas = snapshot.hasData ? snapshot.data![0] as List<Reserva> : <Reserva>[];
              final ingresosMes = snapshot.hasData ? snapshot.data![1] as double : 0.0;
              final total = reservas.length;
              final completadas = reservas.where((r) => r.estado == 'completada').length;
              final tasa = total == 0 ? 0.0 : (completadas / total * 100);
              String masSolicitadoId = '—';
              if (reservas.isNotEmpty) {
                final map = <String, int>{};
                for (final r in reservas) {
                  map[r.profesorId] = (map[r.profesorId] ?? 0) + 1;
                }
                final entry = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                masSolicitadoId = entry.first.key;
              }
              final nombreMasSolicitado = masSolicitadoId == '—'
                  ? Future.value(null)
                  : fs.obtenerProfesor(masSolicitadoId);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildReportItem('Reservas este mes', total.toString()),
                  _buildReportItem('Tasa de finalización', '${tasa.toStringAsFixed(1)}%'),
                  _buildReportItem('Ingresos totales', '\$${ingresosMes.toStringAsFixed(2)}'),
                  FutureBuilder<Profesor?>(
                    future: nombreMasSolicitado,
                    builder: (context, snap) {
                      final nombre = snap.connectionState == ConnectionState.waiting
                          ? '—'
                          : (snap.data?.nombre ?? '—');
                      return _buildReportItem('Profesor más solicitado', nombre);
                    },
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _buildReportItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _exportarReporte(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte exportado correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _gestionarUsuarios(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementScreen()));
  }

  
}
