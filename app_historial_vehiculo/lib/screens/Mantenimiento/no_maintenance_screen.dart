// lib/no_maintenance_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/add_maintenance_screen.dart'; // Importa la nueva pantalla
//import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Posible pantalla a la que ir si ya hay datos
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // For BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // For BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // For BottomNavigationBar


var logger = Logger(printer: PrettyPrinter());

class NoMaintenanceScreen extends StatefulWidget {
  const NoMaintenanceScreen({super.key});

  @override
  State<NoMaintenanceScreen> createState() => _NoMaintenanceScreenState();
}

class _NoMaintenanceScreenState extends State<NoMaintenanceScreen> {
  int _selectedIndex = 2; // "Mantenimiento" está en el índice 2

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    logger.i('Navegación inferior en NoMaintenanceScreen: ${_getBottomNavItemName(index)} (índice: $index)');
    _handleBottomNavigation(index);
  }

  String _getBottomNavItemName(int index) {
    switch (index) {
      case 0: return 'Inicio';
      case 1: return 'Vehículos';
      case 2: return 'Mantenimiento';
      case 3: return 'Gastos';
      case 4: return 'Perfil';
      default: return '';
    }
  }

  void _handleBottomNavigation(int index) {
    Widget screenToNavigate;
    switch (index) {
      case 0: screenToNavigate = const HomeScreen(); break;
      case 1: screenToNavigate = const MyVehiclesListScreen(); break;
      case 2: return; // Ya estamos en Mantenimiento
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mantenimiento',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1E88E5), size: 30),
            onPressed: () {
              logger.i('Botón Añadir Mantenimiento (AppBar) presionado en NoMaintenanceScreen');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMaintenanceScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.build_outlined,
                color: Colors.grey,
                size: 100,
              ),
              const SizedBox(height: 30),
              const Text(
                '¡Aún no tienes registros de mantenimiento!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Añade tu primer registro de mantenimiento para empezar a gestionarlo y mantener tu vehículo en óptimas condiciones.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // Botón "Añadir registro de mantenimiento"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    logger.i('Se hizo clic en "Añadir registro de mantenimiento" desde NoMaintenanceScreen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddMaintenanceScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5), // Color azul del botón
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0), // Bordes redondeados
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Añadir registro de mantenimiento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
