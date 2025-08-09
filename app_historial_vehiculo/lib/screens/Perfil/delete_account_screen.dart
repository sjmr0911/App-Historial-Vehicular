// lib/screens/Perfil/delete_account_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:app_historial_vehiculo/screens/Perfil/account_deleted_screen.dart'; // Importar la pantalla de cuenta eliminada

// Importaciones de pantallas principales para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';


var logger = Logger(printer: PrettyPrinter());

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  // CORRECCIÓN 1: Se declara _auth y _firestore como 'static final'
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Este método debe ser estático o tomar el contexto, y estar definido solo una vez.
  // Lo he movido aquí como un método de instancia, pero podrías hacerlo estático
  // si no dependiera del estado de DeleteAccountScreen (que es un StatelessWidget).
  void _handleBottomNavigation(BuildContext context, int index) {
    Widget screenToNavigate;
    switch (index) {
      case 0: screenToNavigate = const HomeScreen(); break;
      case 1: screenToNavigate = const MyVehiclesListScreen(); break;
      case 2: screenToNavigate = const MaintenanceListScreen(); break;
      case 3: screenToNavigate = const ExpensesScreen(); break;
      case 4: screenToNavigate = const ProfileScreen(); break; // Ya estamos en Perfil (o una sub-pantalla)
      default: return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screenToNavigate),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      logger.e('Error: Usuario no autenticado al intentar eliminar cuenta.');
      return;
    }

    // Para eliminar la cuenta, Firebase requiere re-autenticación reciente.
    // Aquí se asume que el usuario ya ha sido re-autenticado o que se hará en un paso previo.
    // Para una implementación completa, se debería pedir la contraseña actual.
    // Por simplicidad en este ejemplo, se omite el paso de re-autenticación explícita con UI.
    // Si la re-autenticación falla, Firebase lanzará un error 'requires-recent-login'.

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eliminando cuenta...')),
      );
    }

    try {
      // 1. Eliminar datos del usuario de Firestore
      // Esto es un ejemplo. En una app real, podrías tener subcolecciones
      // (vehículos, gastos, mantenimientos, etc.) que también necesitarían ser eliminadas.
      // Firebase Functions es ideal para esto para evitar la eliminación parcial.
      await _firestore.collection('users').doc(user.uid).delete();
      logger.i('Datos de usuario eliminados de Firestore para UID: ${user.uid}');

      // 2. Eliminar la cuenta de autenticación
      await user.delete();
      logger.i('Cuenta de usuario eliminada de Firebase Auth para UID: ${user.uid}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AccountDeletedScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        String errorMessage;
        if (e.code == 'requires-recent-login') {
          errorMessage = 'Por favor, inicie sesión de nuevo para eliminar su cuenta por seguridad.';
        } else {
          errorMessage = 'Error al eliminar cuenta: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      logger.e('Error de Firebase al eliminar cuenta: ${e.code} - ${e.message}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado al eliminar cuenta: $e')),
        );
      }
      logger.e('Error inesperado al eliminar cuenta: $e');
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () {
            logger.i('Volver desde Eliminar Cuenta');
            Navigator.pop(context); // Vuelve a SecurityPrivacyScreen
          },
        ),
        title: const Text(
          'Eliminar Cuenta',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // CORRECCIÓN 2: Se reemplaza .withOpacity(0.1) por .withAlpha(25)
                  color: Colors.red.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: Colors.red,
                  size: 80,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '¿Estás seguro que deseas eliminar tu cuenta?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Esta acción es irreversible y eliminará permanentemente todos tus datos, incluidos vehículos, mantenimientos y gastos. No podrás recuperar tu cuenta.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _deleteAccount(context), // Llama al método de eliminación
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Color rojo para el botón de eliminar
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Eliminar Cuenta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    logger.i('Botón Cancelar presionado en Eliminar Cuenta');
                    Navigator.pop(context); // Vuelve a la pantalla anterior
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    side: BorderSide.none,
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        currentIndex: 4, // Perfil
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          logger.i('Navegación inferior en DeleteAccountScreen: $index');
          // Se llama al método _handleBottomNavigation, pasándole el context
          _handleBottomNavigation(context, index);
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}