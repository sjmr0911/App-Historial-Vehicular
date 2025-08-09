// lib/screens/Perfil/authentication_method_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // Para el BottomNavigationBar


var logger = Logger(printer: PrettyPrinter());

class AuthenticationMethodScreen extends StatefulWidget {
  const AuthenticationMethodScreen({super.key});

  @override
  State<AuthenticationMethodScreen> createState() => _AuthenticationMethodScreenState();
}

enum AuthMethod { sms, authenticatorApp }

class _AuthenticationMethodScreenState extends State<AuthenticationMethodScreen> {
  AuthMethod? _selectedMethod = AuthMethod.sms; // Por defecto, SMS seleccionado

  void _handleBottomNavigation(int index) {
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
            logger.i('Volver desde Método de Autenticación');
            Navigator.pop(context); // Vuelve a SecurityPrivacyScreen
          },
        ),
        title: const Text(
          'Método de Autenticación',
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
              'Selecciona tu método preferido para la autenticación de dos factores:',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            _buildMethodTile(
              title: 'Mensaje de Texto (SMS)',
              value: AuthMethod.sms,
              groupValue: _selectedMethod,
              onChanged: (AuthMethod? value) {
                setState(() {
                  _selectedMethod = value;
                });
                logger.i('Método de autenticación seleccionado: SMS');
              },
            ),
            const SizedBox(height: 16),
            _buildMethodTile(
              title: 'Aplicación de Autenticación',
              value: AuthMethod.authenticatorApp,
              groupValue: _selectedMethod,
              onChanged: (AuthMethod? value) {
                setState(() {
                  _selectedMethod = value;
                });
                logger.i('Método de autenticación seleccionado: Aplicación de Autenticación');
              },
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  logger.i('Botón Guardar Cambios presionado en Método de Autenticación');
                  // Aquí iría la lógica para guardar el método seleccionado
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Método de autenticación guardado: ${_selectedMethod == AuthMethod.sms ? "SMS" : "Aplicación de Autenticación"}')),
                  );
                  Navigator.pop(context); // Vuelve a la pantalla anterior
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 18, color: Colors.white),
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
        currentIndex: 4, // Perfil
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          logger.i('Navegación inferior en AuthenticationMethodScreen: $index');
          _handleBottomNavigation(index); // Delegar la navegación real
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildMethodTile({
    required String title,
    required AuthMethod value,
    required AuthMethod? groupValue,
    required ValueChanged<AuthMethod?> onChanged,
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
      child: RadioListTile<AuthMethod>(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: const Color(0xFF1E88E5), // Color del radio button cuando está seleccionado
      ),
    );
  }
}
