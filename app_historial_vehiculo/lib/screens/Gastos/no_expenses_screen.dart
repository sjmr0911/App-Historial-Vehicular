// lib/screens/Gastos/no_expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/screens/Gastos/add_expense_screen.dart'; // Ruta corregida

// Importaciones de pantallas para la navegación inferior
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Asumo que esta es la pantalla de vehículos principal
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Asumo que esta es la pantalla de mantenimiento principal
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // Asumo que esta es la pantalla de perfil principal


var logger = Logger(printer: PrettyPrinter());

class NoExpensesScreen extends StatefulWidget {
  const NoExpensesScreen({super.key});

  @override
  State<NoExpensesScreen> createState() => _NoExpensesScreenState();
}

class _NoExpensesScreenState extends State<NoExpensesScreen> {
  int _selectedIndex = 3; // "Gastos" está en el índice 3

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    logger.i('Navegación inferior en NoExpensesScreen: ${_getBottomNavItemName(index)} (índice: $index)');
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
      case 2: screenToNavigate = const MaintenanceListScreen(); break;
      case 3: return; // Ya estamos en Gastos
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
          'Gastos',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1E88E5), size: 30),
            onPressed: () {
              logger.i('Botón Añadir Gasto (AppBar) presionado en NoExpensesScreen');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
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
                Icons.account_balance_wallet_outlined,
                color: Colors.grey,
                size: 100,
              ),
              const SizedBox(height: 30),
              const Text(
                '¡Aún no tienes registros de gastos!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Añade tu primer registro de gastos para empezar a llevar un control de tus finanzas y mantener un historial completo de tu vehículo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // Botón "Añadir registro de gastos"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    logger.i('Se hizo clic en "Añadir registro de gastos" desde NoExpensesScreen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
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
                    'Añadir registro de gastos',
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
