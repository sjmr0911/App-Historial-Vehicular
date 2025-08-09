// lib/screens/Recordatorios/reminder_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/models/reminder.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/edit_reminder_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_completed_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/delete_reminder_confirmation_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_deleted_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

var logger = Logger(printer: PrettyPrinter());

class ReminderDetailScreen extends StatefulWidget {
  final Reminder reminder;

  const ReminderDetailScreen({super.key, required this.reminder});

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  late Reminder _currentReminder;
  int _selectedIndex = 1;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _currentReminder = widget.reminder;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Widget screenToNavigate;
    switch (index) {
      case 0:
        screenToNavigate = const HomeScreen();
        break;
      case 1:
        screenToNavigate = const MyVehiclesListScreen();
        break;
      case 2:
        screenToNavigate = const MaintenanceListScreen();
        break;
      case 3:
        screenToNavigate = const ExpensesScreen();
        break;
      case 4:
        screenToNavigate = const ProfileScreen();
        break;
      default:
        return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screenToNavigate),
      (Route<dynamic> route) => false,
    );
  }

  // Función para marcar como completado
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
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .doc(_currentReminder.id)
          .update({'status': 'Completado'});

      setState(() {
        // Usa copyWith para crear una nueva instancia del objeto Reminder
        _currentReminder = _currentReminder.copyWith(status: 'Completado');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ReminderCompletedScreen(completedReminder: _currentReminder)),
          (Route<dynamic> route) => false,
        );
        logger.i('Recordatorio "${_currentReminder.title}" marcado como completado.');
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

  Future<void> _deleteReminder() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      logger.e('Error: Usuario no autenticado al intentar eliminar recordatorio.');
      return;
    }

    final bool? confirmDelete = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeleteReminderConfirmationScreen()),
    );

    if (confirmDelete == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminando recordatorio...')),
        );
      }

      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(_currentReminder.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ReminderDeletedScreen(
                  deletedReminderId: _currentReminder.id,
                  deletedReminderTitle: _currentReminder.title,
                )),
            (Route<dynamic> route) => false,
          );
          logger.i('Recordatorio "${_currentReminder.title}" eliminado exitosamente.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar recordatorio: $e')),
          );
        }
        logger.e('Error al eliminar recordatorio: $e');
      }
    } else {
      logger.i('Eliminación de recordatorio cancelada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        // Se cambió el color de la barra superior de morado a azul
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          _currentReminder.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              logger.i('Botón Editar Recordatorio presionado.');
              final updatedReminder = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditReminderScreen(reminder: _currentReminder)),
              );
              if (updatedReminder != null && updatedReminder is Reminder) {
                setState(() {
                  _currentReminder = updatedReminder;
                });
                logger.i('Recordatorio actualizado desde EditReminderScreen.');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteReminder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(_currentReminder.status),
            const SizedBox(height: 20),
            _buildInfoCard(
              'Detalles del Recordatorio',
              _buildInfoRow('Vehículo', _currentReminder.vehicle, icon: Icons.directions_car, color: Colors.blueAccent),
              _buildInfoRow('Fecha', _currentReminder.date, icon: Icons.calendar_today, color: Colors.green),
              _buildInfoRow('Hora', _currentReminder.time, icon: Icons.access_time, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            _buildNotesCard(_currentReminder.description),
            const SizedBox(height: 30),
            if (_currentReminder.status == 'Pendiente')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _markAsCompleted,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text(
                    'Marcar como Completado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 5,
                    shadowColor: const Color.fromRGBO(76, 175, 80, 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Vehículos'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Mantenimiento'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Gastos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        // Se cambió el color del elemento seleccionado a azul
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    Color cardColor = status == 'Pendiente' ? const Color(0xFFFFE0B2) : const Color(0xFFC8E6C9);
    Color textColor = status == 'Pendiente' ? const Color(0xFFE65100) : const Color(0xFF2E7D32);
    IconData icon = status == 'Pendiente' ? Icons.access_time : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: textColor.withAlpha((0.3 * 255).round()),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 8),
          Text(
            'Estado: $status',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoCard(String title, Widget row1, Widget row2, Widget row3) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Divider(height: 30, thickness: 1, color: Color(0xFFE0E0E0)),
            row1,
            const Divider(height: 20, thickness: 0.5),
            row2,
            const Divider(height: 20, thickness: 0.5),
            row3,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNotesCard(String notes) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Divider(height: 30, thickness: 1, color: Color(0xFFE0E0E0)),
            Text(
              notes.isNotEmpty ? notes : 'No hay notas adicionales.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
