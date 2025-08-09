// lib/screens/vehicle_added_success_screen.dart
import 'package:flutter/material.dart';
// Mantener la importación de my_vehicles_list_screen para la navegación del botón.
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';


class VehicleAddedSuccessScreen extends StatelessWidget {
  const VehicleAddedSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehículo Agregado'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            // Navigate back to MyVehiclesListScreen, clearing other routes
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MyVehiclesListScreen(hasVehicle: true)),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Vehículo agregado con éxito!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Tu vehículo ha sido agregado exitosamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to MyVehiclesListScreen, clearing other routes
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MyVehiclesListScreen(hasVehicle: true)),
                    (Route<dynamic> route) => false, // Remove all routes
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Volver a Vehículos',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      // Se ha eliminado el BottomNavigationBar
      // bottomNavigationBar: BottomNavigationBar(...),
    );
  }
}
