// lib/screens/Vehiculos/reminder_completed_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/models/reminder.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

var logger = Logger(printer: PrettyPrinter());

class ReminderCompletedScreen extends StatefulWidget {
  final Reminder completedReminder;

  const ReminderCompletedScreen({super.key, required this.completedReminder});

  @override
  State<ReminderCompletedScreen> createState() => _ReminderCompletedScreenState();
}

class _ReminderCompletedScreenState extends State<ReminderCompletedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _createCompletedNotification();
  }

  Future<void> _createCompletedNotification() async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Error: Usuario no autenticado al crear notificación de recordatorio completado.');
      return;
    }

    try {
      // Se utiliza el color verde para la notificación de completado
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
            'title': '¡Recordatorio completado! "${widget.completedReminder.title}" para ${widget.completedReminder.vehicle}.',
            'iconCodePoint': Icons.check_circle_outline.codePoint,
            'iconFontFamily': 'MaterialIcons',
            'iconColorValue': Colors.green.value, // Se utiliza .value para obtener el entero
            'read': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
      logger.i('Notificación de recordatorio completado creada con éxito.');
    } catch (e) {
      logger.e('Error al crear notificación de recordatorio completado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            logger.i('Volver desde Recordatorio Completado (AppBar)');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MyVehiclesListScreen(hasVehicle: true)),
              (Route<dynamic> route) => false,
            );
          },
        ),
        title: const Text(
          'Recordatorio Completado',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 30),
              const Text(
                '¡Recordatorio completado con éxito!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'El recordatorio "${widget.completedReminder.title}" para el vehículo "${widget.completedReminder.vehicle}" ha sido marcado como completado.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    logger.i('Volver a Recordatorios (desde Recordatorio Completado)');
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MyVehiclesListScreen(hasVehicle: true)),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Volver a Recordatorios',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
