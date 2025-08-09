// lib/screens/Perfil/two_factor_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/screens/Perfil/authentication_method_screen.dart'; // Para Método de autenticación
import 'package:app_historial_vehiculo/screens/Perfil/recovery_codes_screen.dart'; // Para Códigos de recuperación
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';


var logger = Logger(printer: PrettyPrinter());

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  bool _isTwoFactorEnabled = false; // State of the "Enable Two-Factor Authentication" toggle
  int _selectedIndex = 4; // Assuming 'Perfil' (index 4) is selected for the bottom nav bar

  void _handleBottomNavigation(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
            logger.i('Volver desde Autenticación de Dos Factores');
            Navigator.pop(context); // Vuelve a SecurityPrivacyScreen
          },
        ),
        title: const Text(
          'Autenticación de Dos Factores',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(bottom: 24.0),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  children: [
                    const Icon(Icons.security_update_good, color: Colors.black87, size: 24),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Habilitar Autenticación de Dos Factores',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isTwoFactorEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _isTwoFactorEnabled = value;
                        });
                        if (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Autenticación de dos factores habilitada.')),
                          );
                          logger.i('Autenticación de dos factores habilitada.');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Autenticación de dos factores deshabilitada.')),
                          );
                          logger.i('Autenticación de dos factores deshabilitada.');
                        }
                      },
                      activeColor: const Color(0xFF1E88E5),
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              'Configuración de 2FA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.phone_android_outlined,
              title: 'Método de Autenticación',
              onTap: _isTwoFactorEnabled ? () {
                logger.i('Navegando a Método de Autenticación');
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthenticationMethodScreen()));
              } : null, // Disable if 2FA is not enabled
              isEnabled: _isTwoFactorEnabled,
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.qr_code_outlined,
              title: 'Códigos de Recuperación',
              onTap: _isTwoFactorEnabled ? () {
                logger.i('Navegando a Códigos de Recuperación');
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RecoveryCodesScreen()));
              } : null, // Disable if 2FA is not enabled
              isEnabled: _isTwoFactorEnabled,
            ),
            const SizedBox(height: 30),
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
        currentIndex: _selectedIndex, // Perfil
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: _handleBottomNavigation,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback? onTap, // Can be null if disabled
    bool isEnabled = true, // New parameter to control enabled state
  }) {
    Color textColor = isEnabled ? Colors.black87 : Colors.grey[600]!;
    Color iconColor = isEnabled ? Colors.black87 : Colors.grey[400]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0), // Added some margin for spacing
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
          onTap: onTap, // onTap will be null if the option is disabled
          borderRadius: BorderRadius.circular(10.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24), // Use conditional color
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor, // Use conditional color
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: iconColor, size: 18), // Use conditional color
              ],
            ),
          ),
        ),
      ),
    );
  }
}
