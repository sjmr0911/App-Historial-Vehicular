// lib/delete_maintenance_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

var logger = Logger(printer: PrettyPrinter());

class DeleteMaintenanceConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> maintenance;

  const DeleteMaintenanceConfirmationScreen({super.key, required this.maintenance});

  @override
  State<DeleteMaintenanceConfirmationScreen> createState() => _DeleteMaintenanceConfirmationScreenState();
}

class _DeleteMaintenanceConfirmationScreenState extends State<DeleteMaintenanceConfirmationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isDeleting = false;

  // Método para manejar la navegación inferior
  void _handleBottomNavigation(BuildContext context, int index) {
    Widget screenToNavigate;
    switch (index) {
      case 0: screenToNavigate = const HomeScreen(); break;
      case 1: screenToNavigate = const MyVehiclesListScreen(); break;
      case 2: screenToNavigate = const MaintenanceListScreen(); break;
      case 3: screenToNavigate = const ExpensesScreen(); break;
      case 4: screenToNavigate = const ProfileScreen(); break;
      default: return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screenToNavigate),
      (Route<dynamic> route) => false,
    );
  }

  // --- Nueva función para crear la notificación ---
  Future<void> _createDeletionNotification(String maintenanceType) async {
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
            'title': 'Registro de mantenimiento eliminado: $maintenanceType',
            'iconCodePoint': Icons.delete_forever_outlined.codePoint,
            'iconFontFamily': 'MaterialIcons',
            'iconColorValue': Colors.red.toARGB32(),
            'read': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
      logger.i('Notificación de eliminación de mantenimiento creada con éxito.');
    } catch (e) {
      logger.e('Error al crear notificación de eliminación: $e');
    }
  }

  // --- Nueva función para eliminar el mantenimiento ---
  Future<void> _deleteMaintenance() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final maintenanceId = widget.maintenance['id'];
      final maintenanceType = widget.maintenance['tipoMantenimiento'] ?? 'Sin tipo';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('maintenances')
          .doc(maintenanceId)
          .delete();

      // Llamada a la nueva función de notificación
      await _createDeletionNotification(maintenanceType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mantenimiento eliminado con éxito.')),
        );
        Navigator.pop(context, true); // Go back, confirming deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar mantenimiento: $e')),
        );
      }
      logger.e('Error al eliminar mantenimiento: $e');
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eliminar Mantenimiento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, false); // Go back to MaintenanceDetailScreen, indicating cancellation
          },
        ),
      ),
      body: Center(
        child: _isDeleting
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 100,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Estás seguro que deseas eliminar este registro de mantenimiento? Esta acción no se puede deshacer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, false); // Cancel deletion
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _deleteMaintenance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Vehículos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Mantenimiento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Gastos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: 2, // Assuming Mantenimiento is the 3rd tab (index 2)
        selectedItemColor: Colors.blue,
        onTap: (index) {
          _handleBottomNavigation(context, index);
        },
      ),
    );
  }
}
