// lib/screens/Perfil/security_privacy_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/screens/Perfil/change_password_screen.dart'; // Para Cambiar Contraseña
import 'package:app_historial_vehiculo/screens/Perfil/two_factor_auth_screen.dart'; // Para Autenticación de dos factores
import 'package:app_historial_vehiculo/screens/Perfil/privacy_policy_screen.dart'; // Para Política de Privacidad
import 'package:app_historial_vehiculo/screens/Perfil/terms_conditions_screen.dart'; // Para Términos y Condiciones
import 'package:app_historial_vehiculo/screens/Perfil/delete_account_screen.dart'; // Para Eliminar Cuenta

// Importaciones de pantallas principales para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';


var logger = Logger(printer: PrettyPrinter());

class SecurityPrivacyScreen extends StatelessWidget {
  const SecurityPrivacyScreen({super.key});

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
            logger.i('Volver desde Seguridad y Privacidad');
            Navigator.pop(context); // Vuelve a ProfileScreen
          },
        ),
        title: const Text(
          'Seguridad y Privacidad',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Seguridad de la Cuenta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.vpn_key_outlined,
              title: 'Cambiar Contraseña',
              onTap: () {
                logger.i('Navegando a Cambiar Contraseña');
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.security_outlined,
              title: 'Autenticación de Dos Factores',
              onTap: () {
                logger.i('Navegando a Autenticación de Dos Factores');
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TwoFactorAuthScreen()));
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Privacidad y Datos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Política de Privacidad',
              onTap: () {
                logger.i('Navegando a Política de Privacidad');
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.description_outlined,
              title: 'Términos y Condiciones',
              onTap: () {
                logger.i('Navegando a Términos y Condiciones');
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsConditionsScreen()));
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Gestión de Cuenta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.delete_forever_outlined,
              title: 'Eliminar Cuenta',
              onTap: () {
                logger.i('Navegando a Eliminar Cuenta');
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DeleteAccountScreen()));
              },
              color: Colors.red, // Resaltar esta opción
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
        currentIndex: 4, // Perfil
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          logger.i('Navegación inferior en SecurityPrivacyScreen: $index');
          _handleBottomNavigation(context, index); // Delega a un método para evitar duplicación
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87, // Default color for text and icon
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(0x1f),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

