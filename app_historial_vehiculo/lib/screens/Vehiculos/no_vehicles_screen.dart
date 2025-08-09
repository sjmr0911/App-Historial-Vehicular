// lib/screens/Vehiculos/no_vehicles_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/add_vehicle_screen.dart'; // Para el botón "Añadir vehículo"

// Importaciones de pantallas para la navegación inferior
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
//import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Asumo que esta es la pantalla de vehículos principal
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Asumo que esta es la pantalla de mantenimiento principal
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // Asumo que esta es la pantalla de gastos principal
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // Asumo que esta es la pantalla de perfil principal


var logger = Logger(printer: PrettyPrinter());

class NoVehiclesScreen extends StatefulWidget {
  const NoVehiclesScreen({super.key});

  @override
  State<NoVehiclesScreen> createState() => _NoVehiclesScreenState();
}

class _NoVehiclesScreenState extends State<NoVehiclesScreen> {
  int _selectedIndex = 1; // "Vehículos" está en el índice 1

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _handleBottomNavigation(index);
  }

  void _handleBottomNavigation(int index) {
    Widget screenToNavigate;
    switch (index) {
      case 0: screenToNavigate = const HomeScreen(); break;
      case 1: return; // Ya estamos en Vehículos
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mis Vehículos',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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
                Icons.directions_car_outlined,
                color: Colors.grey,
                size: 100,
              ),
              const SizedBox(height: 30),
              const Text(
                '¡Aún no tienes vehículos!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Parece que aún no has añadido ningún vehículo. ¡Añade tu primer vehículo para empezar a gestionarlo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 40),

              // Botón "Añadir vehículo"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    logger.i('Se hizo clic en "Añadir vehículo" desde NoVehiclesScreen');
                    // Redirigir a la pantalla para añadir vehículo (add_vehicle_screen.dart)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
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
                    'Añadir vehículo',
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
