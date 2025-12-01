import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class AvailabilityScreen extends StatefulWidget {
  @override
  _AvailabilityScreenState createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final Map<String, List<TimeSlot>> _disponibilidad = {};
  final TextEditingController _tarifaController = TextEditingController(text: '50.00');

  @override
  void initState() {
    super.initState();
    _inicializarDisponibilidad();
    _cargarDisponibilidad();
  }

  void _inicializarDisponibilidad() {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    
    for (var dia in dias) {
      _disponibilidad[dia] = [];
    }
  }

  Future<void> _cargarDisponibilidad() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final user = auth.usuario;
    if (user == null) return;
    final disp = await fs.obtenerDisponibilidad(user.id);
    if (disp == null) return;
    final tarifa = (disp['tarifaHora'] as num?)?.toDouble() ?? 0.0;
    final slots = disp['slots'] as Map<String, dynamic>?;
    setState(() {
      _tarifaController.text = tarifa.toStringAsFixed(2);
      if (slots != null) {
        slots.forEach((dia, lista) {
          final l = (lista as List)
              .map((e) => TimeSlot(
                    inicio: _parseTimeOfDay(e['inicio'] as String),
                    fin: _parseTimeOfDay(e['fin'] as String),
                  ))
              .toList();
          _disponibilidad[dia] = l;
        });
      }
    });
  }

  TimeOfDay _parseTimeOfDay(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Disponibilidad y Tarifas')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Configuración de tarifa
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarifa por Hora',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _tarifaController,
                      decoration: InputDecoration(
                        prefixText: '\$',
                        labelText: 'Tarifa por hora',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Disponibilidad por días
            Expanded(
              child: ListView(
                children: _disponibilidad.keys.map((dia) {
                  return _buildDayCard(dia);
                }).toList(),
              ),
            ),
            
            // Botón guardar
            ElevatedButton(
              onPressed: _guardarDisponibilidad,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Guardar Disponibilidad y Tarifa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(String dia) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dia,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Switch(
                  value: _disponibilidad[dia]!.isNotEmpty,
                  onChanged: (value) {
                    setState(() {
                      if (value) {
                        _disponibilidad[dia]!.add(TimeSlot(
                          inicio: TimeOfDay(hour: 9, minute: 0),
                          fin: TimeOfDay(hour: 17, minute: 0),
                        ));
                      } else {
                        _disponibilidad[dia]!.clear();
                      }
                    });
                  },
                ),
              ],
            ),
            
            if (_disponibilidad[dia]!.isNotEmpty) ...[
              SizedBox(height: 10),
              ..._disponibilidad[dia]!.asMap().entries.map((entry) {
                final index = entry.key;
                final slot = entry.value;
                return _buildTimeSlot(dia, index, slot);
              }).toList(),
              
              ElevatedButton(
                onPressed: () => _agregarTimeSlot(dia),
                child: Text('Agregar Horario'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String dia, int index, TimeSlot slot) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _seleccionarHoraInicio(dia, index),
            child: Text('Inicio: ${slot.inicio.format(context)}'),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _seleccionarHoraFin(dia, index),
            child: Text('Fin: ${slot.fin.format(context)}'),
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _eliminarTimeSlot(dia, index),
        ),
      ],
    );
  }

  Future<void> _seleccionarHoraInicio(String dia, int index) async {
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: _disponibilidad[dia]![index].inicio,
    );
    
    if (selected != null) {
      setState(() {
        _disponibilidad[dia]![index].inicio = selected;
      });
    }
  }

  Future<void> _seleccionarHoraFin(String dia, int index) async {
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: _disponibilidad[dia]![index].fin,
    );
    
    if (selected != null) {
      setState(() {
        _disponibilidad[dia]![index].fin = selected;
      });
    }
  }

  void _agregarTimeSlot(String dia) {
    setState(() {
      _disponibilidad[dia]!.add(TimeSlot(
        inicio: TimeOfDay(hour: 9, minute: 0),
        fin: TimeOfDay(hour: 17, minute: 0),
      ));
    });
  }

  void _eliminarTimeSlot(String dia, int index) {
    setState(() {
      _disponibilidad[dia]!.removeAt(index);
    });
  }

  void _guardarDisponibilidad() {
    final tarifa = double.tryParse(_tarifaController.text) ?? 50.0;
    final slotsPorDia = <String, List<Map<String, String>>>{};
    _disponibilidad.forEach((dia, slots) {
      slotsPorDia[dia] = slots
          .map((s) => {
                'inicio': _formatTime(s.inicio),
                'fin': _formatTime(s.fin),
              })
          .toList();
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final user = auth.usuario;
    if (user == null || user.tipo != 'profesor') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes iniciar sesión como profesor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final profesorId = user.id;

    firestore.guardarDisponibilidad(profesorId, tarifa, slotsPorDia).then((_) {
      return firestore.actualizarProfesorTarifa(profesorId, tarifa);
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disponibilidad y tarifa guardadas correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }).catchError((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar disponibilidad'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  String _formatTime(TimeOfDay t) {
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }
}

class TimeSlot {
  TimeOfDay inicio;
  TimeOfDay fin;
  
  TimeSlot({required this.inicio, required this.fin});
}
