// lib/screens/Recordatorios/add_reminder_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:app_historial_vehiculo/models/reminder.dart';
import 'package:app_historial_vehiculo/models/vehicle.dart' as vehicle_model;
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_added_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

var logger = Logger(printer: PrettyPrinter());

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedVehicleId;
  String? _selectedVehicleName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      initialDate: _selectedDate ?? DateTime.now(),
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
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
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
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
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

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedVehicleId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, selecciona un vehículo.')),
          );
        }
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Usuario no autenticado.')),
          );
        }
        logger.e('Error: Usuario no autenticado al intentar guardar recordatorio.');
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardando recordatorio...')),
        );
      }

      try {
        final newReminder = Reminder(
          id: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('reminders').doc().id,
          title: _titleController.text.trim(),
          description: _notesController.text.trim(),
          vehicle: _selectedVehicleName!,
          vehicleId: _selectedVehicleId!,
          date: _dateController.text,
          time: _timeController.text,
          status: 'Pendiente',
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(newReminder.id)
            .set(newReminder.toJson());

        // La lógica para crear una notificación interactiva y con contenido dinámico
        // no se puede manejar solo con una entrada en Firestore. Para que el usuario
        // vea una notificación en su dispositivo que pueda dirigirlo a una pantalla
        // específica o que tenga un temporizador, es necesario utilizar un paquete
        // como `flutter_local_notifications`. La entrada en Firestore solo sirve
        // como un registro estático para tu aplicación.

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
              'title': 'Se ha creado el recordatorio "${newReminder.title}" para tu vehículo "${newReminder.vehicle}".',
              'iconCodePoint': Icons.event.codePoint,
              'iconFontFamily': 'MaterialIcons',
              'iconColorValue': Colors.green.toARGB32(),
              'read': false,
              'timestamp': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ReminderAddedScreen(addedReminder: newReminder)),
            (Route<dynamic> route) => false,
          );
          logger.i('Recordatorio "${newReminder.title}" agregado exitosamente.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar recordatorio: $e')),
          );
        }
        logger.e('Error al guardar recordatorio: $e');
      }
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
          'Añadir Recordatorio',
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
                'Ej: Cambio de aceite',
                _titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Vehículo',
                style: TextStyle(
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
                child: StreamBuilder<QuerySnapshot<vehicle_model.Vehicle>>(
                  stream: user != null
                      ? _firestore.collection('users').doc(user.uid).collection('vehicles').withConverter<vehicle_model.Vehicle>(
                          fromFirestore: (DocumentSnapshot<Map<String, dynamic>> snapshot, _) => vehicle_model.Vehicle.fromFirestore(snapshot),
                          toFirestore: (vehicle, _) => vehicle.toFirestore(),
                        ).snapshots()
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

                    List<vehicle_model.Vehicle> vehicles = snapshot.data!.docs
                        .map((doc) => doc.data())
                        .toList();

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
                          _selectedVehicleName = vehicles.firstWhere((v) => v.id == newValue!).name;
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
              _buildTextField(
                'Fecha',
                'DD/MM/AAAA',
                _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                suffixIcon: const Icon(Icons.calendar_today),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa la fecha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Hora',
                'HH:MM AM/PM',
                _timeController,
                readOnly: true,
                onTap: () => _selectTime(context),
                suffixIcon: const Icon(Icons.access_time),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa la hora';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Notas Adicionales',
                'Ej: Próximo cambio de aceite...',
                _notesController,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Guardar Recordatorio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller,
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
            hintText: hint,
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
}
