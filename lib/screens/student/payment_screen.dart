import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/profesor.dart';
import '../../models/reserva.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class PaymentScreen extends StatelessWidget {
  final Profesor profesor;
  final DateTime fecha;
  final int duracion;
  final String modalidad;

  const PaymentScreen({Key? key, required this.profesor, required this.fecha, required this.duracion, required this.modalidad}) : super(key: key);

  double get total => duracion / 60 * profesor.tarifaHora;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pago')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen de Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Profesor: ${profesor.nombre}'),
            Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}'),
            Text('Duración: ${duracion} min'),
            SizedBox(height: 12),
            Text('Total: \$${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pagar con Yape', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Número: 933434703', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Realiza el pago y confirma abajo.'),
                  ],
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () => _confirmarPago(context),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              child: Text('He pagado por Yape'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarPago(BuildContext context) async {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.usuario;
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Inicia sesión'),
          content: Text('Debes iniciar sesión para confirmar el pago'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK'))],
        ),
      );
      return;
    }

    final reserva = Reserva(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      estudianteId: user.id,
      profesorId: profesor.id,
      fecha: fecha,
      duracion: duracion,
      modalidad: modalidad,
      estado: 'confirmada',
      precio: total,
    );

    try {
      final ok = await fs.verificarDisponibilidad(profesor.id, fecha, duracion);
      if (!ok) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Horario no disponible'),
            content: Text('El horario elegido ya no está disponible.'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK'))],
          ),
        );
        return;
      }

      await fs.crearReserva(reserva);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Pago confirmado'),
          content: Text('Tu clase ha sido reservada exitosamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('No se pudo confirmar el pago: ${e}'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK'))],
        ),
      );
    }
  }
}

