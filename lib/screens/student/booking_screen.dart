import 'package:flutter/material.dart';
import '../../models/profesor.dart';
import '../../models/reserva.dart';
import 'payment_screen.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

class BookingScreen extends StatefulWidget {
  final Profesor profesor;

  const BookingScreen({Key? key, required this.profesor}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  String _modalidad = 'online';
  final int _duracion = 60; // 60 minutos por defecto
  List<DateTime> _slotsDisponibles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reservar Clase')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profesor: ${widget.profesor.nombre}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Instrumento: ${widget.profesor.instrumento}'),
            Text('Tarifa: \$${widget.profesor.tarifaHora.toStringAsFixed(2)}/hora'),
            SizedBox(height: 20),
            
            // Selector de fecha
            ElevatedButton(
              onPressed: _seleccionarFecha,
              child: Text(_fechaSeleccionada == null 
                  ? 'Seleccionar Fecha' 
                  : 'Fecha: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}'),
            ),
            
            SizedBox(height: 10),
            
            // Selector de horario (9am-5pm, 1h) sólo disponibles
            if (_fechaSeleccionada != null) ...[
              Text('Horarios disponibles (9:00 - 17:00):'),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slotsDisponibles.map((dt) {
                  final sel = _horaSeleccionada != null && _toDateTimeFromSelected() == dt;
                  return ChoiceChip(
                    label: Text(_formatHora(dt)),
                    selected: sel,
                    onSelected: (_) {
                      setState(() {
                        _horaSeleccionada = TimeOfDay(hour: dt.hour, minute: dt.minute);
                      });
                    },
                  );
                }).toList(),
              ),
            ] else ...[
              Text('Selecciona una fecha para ver horarios disponibles'),
            ],
            
            SizedBox(height: 20),
            
            // Selector de modalidad
            DropdownButtonFormField<String>(
              value: _modalidad,
              decoration: InputDecoration(labelText: 'Modalidad'),
              items: ['online', 'presencial'].map((modalidad) {
                return DropdownMenuItem(
                  value: modalidad,
                  child: Text(modalidad == 'online' ? 'Online' : 'Presencial'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _modalidad = value!;
                });
              },
            ),
            
            SizedBox(height: 20),
            
            // Resumen y pago
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Resumen de la Clase', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Duración:'),
                        Text('$_duracion minutos'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Precio:'),
                        Text('\$${(_duracion / 60 * widget.profesor.tarifaHora).toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            Spacer(),
            
            ElevatedButton(
              onPressed: _puedeReservar() ? _confirmarReserva : null,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
      await _actualizarSlotsDisponibles();
    }
  }

  Future<void> _actualizarSlotsDisponibles() async {
    if (_fechaSeleccionada == null) return;
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final slots = await fs.obtenerSlotsDisponibles(widget.profesor.id, _fechaSeleccionada!, _duracion);
    setState(() {
      _slotsDisponibles = slots;
      _horaSeleccionada = null;
    });
  }

  bool _puedeReservar() {
    return _fechaSeleccionada != null && _horaSeleccionada != null;
  }

  void _confirmarReserva() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.usuario == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Inicia sesión'),
          content: Text('Debes iniciar sesión para reservar'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK'))],
        ),
      );
      return;
    }
    
    // Combinar fecha y hora
    final fechaCompleta = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );
    
    final puede = await firestoreService.verificarDisponibilidad(widget.profesor.id, fechaCompleta, _duracion);
    if (!puede) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Horario no disponible'),
          content: Text('El profesor no está disponible en el horario seleccionado o ya está reservado.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK')),
          ],
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          profesor: widget.profesor,
          fecha: fechaCompleta,
          duracion: _duracion,
          modalidad: _modalidad,
        ),
      ),
    );
  }

  DateTime _toDateTimeFromSelected() {
    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      return DateTime(0);
    }
    return DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );
  }

  String _formatHora(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }
}
