// lib/recovery_codes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para Clipboard
import 'package:logger/logger.dart';
import 'dart:math'; // Para generar números aleatorios
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para navegación de vehículos
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Para navegación de mantenimiento
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // Para navegación de gastos
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // Para navegación de perfil


var logger = Logger(printer: PrettyPrinter());

class RecoveryCodesScreen extends StatefulWidget {
  const RecoveryCodesScreen({super.key});

  @override
  State<RecoveryCodesScreen> createState() => _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends State<RecoveryCodesScreen> {
  List<String> _recoveryCodes = [];
  int _selectedIndex = 4; // Asumiendo 'Perfil' (índice 4) está seleccionado para la barra de navegación inferior

  @override
  void initState() {
    super.initState();
    _generateNewCodes(); // Generar códigos al iniciar la pantalla
  }

  void _generateNewCodes() {
    setState(() {
      _recoveryCodes = List.generate(10, (_) => _generateRandomCode());
    });
    logger.i('Códigos de recuperación generados.');
  }

  String _generateRandomCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }

  void _copyCodesToClipboard() {
    final codesText = _recoveryCodes.join('\n');
    Clipboard.setData(ClipboardData(text: codesText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Códigos copiados al portapapeles.')),
      );
    }
    logger.i('Códigos de recuperación copiados al portapapeles.');
  }

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
            logger.i('Volver desde Códigos de Recuperación');
            Navigator.pop(context); // Vuelve a TwoFactorAuthScreen
          },
        ),
        title: const Text(
          'Códigos de Recuperación',
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
              'Estos códigos de un solo uso te permiten acceder a tu cuenta si pierdes tu teléfono o no puedes recibir códigos a través de tu método de autenticación principal.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.grey.shade300, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Guarda estos códigos en un lugar seguro:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  ..._recoveryCodes.map((code) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'monospace', // Para que los códigos se vean más claros
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _copyCodesToClipboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Copiar códigos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _generateNewCodes,
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
                  'Generar nuevos códigos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
}
