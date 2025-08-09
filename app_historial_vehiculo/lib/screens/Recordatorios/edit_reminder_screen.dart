// lib/screens/Recordatorios/edit_reminder_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:app_historial_vehiculo/models/reminder.dart'; // Importa el modelo Reminder
import 'package:app_historial_vehiculo/models/vehicle.dart'; // Importa el modelo Vehicle
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_completed_screen.dart'; // Para el éxito de completado
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_added_screen.dart'; // Para éxito de guardado (puede ser el mismo que "saved")
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

var logger = Logger(printer: PrettyPrinter());

class EditReminderScreen extends StatefulWidget {
  final Reminder reminder;

  const EditReminderScreen({super.key, required this.reminder});

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _notesController;

  String? _selectedVehicleId; // CORRECCIÓN: Ahora puede ser nulo
  String? _selectedVehicleName; // CORRECCIÓN: Ahora puede ser nulo
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _status;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    _dateController = TextEditingController(text: widget.reminder.date);
    _timeController = TextEditingController(text: widget.reminder.time);
    _notesController = TextEditingController(text: widget.reminder.description); // CORRECCIÓN: Usa description en lugar de notes

    _selectedVehicleId = widget.reminder.vehicleId;
    _selectedVehicleName = widget.reminder.vehicle;

    try {
      _selectedDate = DateFormat('dd/MM/yyyy').parse(widget.reminder.date);
      final timeParts = widget.reminder.time.split(RegExp(r'[: ]'));
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
      if (widget.reminder.time.toUpperCase().contains('PM') && _selectedTime.hour < 12) {
        _selectedTime = TimeOfDay(hour: _selectedTime.hour + 12, minute: _selectedTime.minute);
      } else if (widget.reminder.time.toUpperCase().contains('AM') && _selectedTime.hour == 12) {
        _selectedTime = TimeOfDay(hour: 0, minute: _selectedTime.minute);
      }
    } catch (e) {
      logger.e('Error al parsear fecha/hora del recordatorio: $e');
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
    _status = widget.reminder.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white), // CORRECCIÓN: Usa dialogTheme
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      logger.i('Fecha seleccionada: ${_dateController.text}');
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white), // CORRECCIÓN: Usa dialogTheme
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
      logger.i('Hora seleccionada: ${_timeController.text}');
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Usuario no autenticado.')),
          );
        }
        logger.e('Error: Usuario no autenticado al intentar guardar cambios del recordatorio.');
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardando cambios...')),
        );
      }

      try {
        final updatedReminder = widget.reminder.copyWith(
          title: _titleController.text.trim(),
          vehicle: _selectedVehicleName,
          vehicleId: _selectedVehicleId,
          date: _dateController.text,
          time: _timeController.text,
          description: _notesController.text.trim(), // CORRECCIÓN: Usa description
          status: _status,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(updatedReminder.id)
            .update(updatedReminder.toJson());

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ReminderAddedScreen(addedReminder: updatedReminder)),
            (Route<dynamic> route) => false,
          );
          logger.i('Recordatorio "${updatedReminder.title}" actualizado exitosamente.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar cambios del recordatorio: $e')),
          );
        }
        logger.e('Error al guardar cambios del recordatorio: $e');
      }
    }
  }

  Future<void> _markAsCompleted() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      logger.e('Error: Usuario no autenticado al intentar marcar recordatorio como completado.');
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marcando como completado...')),
      );
    }

    try {
      final completedReminder = widget.reminder.copyWith(status: 'Completado'); // CORRECCIÓN: Usa copyWith

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .doc(completedReminder.id)
          .update({'status': 'Completado'});

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ReminderCompletedScreen(completedReminder: completedReminder)),
          (Route<dynamic> route) => false,
        );
        logger.i('Recordatorio "${completedReminder.title}" marcado como completado.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al marcar como completado: $e')),
        );
      }
      logger.e('Error al marcar recordatorio como completado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Editar Recordatorio',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                'Título del Recordatorio',
                _titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Vehículo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey.shade300, width: 1.0),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: user != null
                      ? _firestore.collection('users').doc(user.uid).collection('vehicles').snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No hay vehículos disponibles.'));
                    }

                    List<Vehicle> vehicles = snapshot.data!.docs
                        .map((doc) => Vehicle.fromFirestore(doc))
                        .toList();

                    if (!vehicles.any((v) => v.id == _selectedVehicleId)) {
                      _selectedVehicleId = vehicles.isNotEmpty ? vehicles.first.id : null;
                      _selectedVehicleName = vehicles.isNotEmpty ? vehicles.first.name : null; // CORRECCIÓN: Ahora puede ser nulo
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedVehicleId,
                      hint: const Text('Selecciona un vehículo'),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      items: vehicles.map((vehicle) {
                        return DropdownMenuItem<String>(
                          value: vehicle.id,
                          child: Text('${vehicle.name} ${vehicle.brandModel}'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedVehicleId = newValue;
                          _selectedVehicleName = vehicles.firstWhere((v) => v.id == newValue).name;
                        });
                        logger.i('Vehículo seleccionado: $_selectedVehicleName (ID: $_selectedVehicleId)');
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecciona un vehículo';
                        }
                        return null;
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildDateField(
                'Fecha',
                _dateController,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),
              _buildTimeField(
                'Hora',
                _timeController,
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 20),
              _buildNotesField(
                'Notas Adicionales',
                _notesController,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Guardar Cambios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              if (_status == 'Pendiente')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _markAsCompleted,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Marcar como Completado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false, VoidCallback? onTap, Widget? suffixIcon, int maxLines = 1, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2.0),
            ),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, {VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: 'Selecciona la fecha',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(Icons.calendar_today),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, ingresa la fecha';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TextEditingController controller, {VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: 'Selecciona la hora',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(Icons.access_time),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, ingresa la hora';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotesField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Notas adicionales sobre el recordatorio...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}