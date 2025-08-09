// lib/screens/Vehiculos/reminder_deleted_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

var logger = Logger(printer: PrettyPrinter());

class ReminderDeletedScreen extends StatefulWidget {
  final String deletedReminderId;
  final String deletedReminderTitle;

  const ReminderDeletedScreen({
    super.key,
    required this.deletedReminderId,
    required this.deletedReminderTitle,
  });

  @override
  State<ReminderDeletedScreen> createState() => _ReminderDeletedScreenState();
}

class _ReminderDeletedScreenState extends State<ReminderDeletedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _createDeleteNotification();
  }

  Future<void> _createDeleteNotification() async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Error: Usuario no autenticado al crear notificación de eliminación.');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
            'title': 'Se ha eliminado el recordatorio "${widget.deletedReminderTitle}".',
            'iconCodePoint': Icons.delete_forever.codePoint,
            'iconFontFamily': 'MaterialIcons',
            'iconColorValue': Colors.red.toARGB32(), // Se corrigió a .value para obtener el entero del color
            'read': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
      logger.i('Notificación de recordatorio eliminado creada con éxito.');
    } catch (e) {
      logger.e('Error al crear notificación de recordatorio eliminado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Recordatorio Eliminado',
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
              Text(
                '¡El recordatorio "${widget.deletedReminderTitle}" ha sido eliminado con éxito!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'El recordatorio con ID: ${widget.deletedReminderId} ha sido eliminado permanentemente.',
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
                    logger.i('Volver a Recordatorios (desde Recordatorio Eliminado)');
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
