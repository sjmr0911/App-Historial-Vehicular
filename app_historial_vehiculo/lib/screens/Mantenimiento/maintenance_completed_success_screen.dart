// lib/maintenance_completed_success_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';

var logger = Logger(printer: PrettyPrinter());

class MaintenanceCompletedSuccessScreen extends StatelessWidget {
  // CORRECCIÓN: El constructor ya no requiere el objeto maintenance
  const MaintenanceCompletedSuccessScreen({super.key});

  void _handleBottomNavigation(BuildContext context, int index) {
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

  void _navigateToMaintenanceList(BuildContext context) {
    logger.i('Navegando a la lista de mantenimientos y borrando el historial.');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MaintenanceListScreen()),
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
            _navigateToMaintenanceList(context);
          },
        ),
        title: const Text(
          'Mantenimiento Completado',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 30),
              const Text(
                '¡Mantenimiento marcado como completado!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'El registro de mantenimiento ha sido actualizado exitosamente.',
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
                  onPressed: () {
                    _navigateToMaintenanceList(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Volver a Mantenimiento',
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
        currentIndex: 2,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          logger.i('Navegación inferior en MaintenanceCompletedSuccessScreen: $index');
          _handleBottomNavigation(context, index);
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}