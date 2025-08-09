import 'package:flutter/material.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // To navigate back to vehicles list
//import 'package:app_historial_vehiculo/screens/Vehiculos/vehicle_detail_screen.dart'; // Para volver al detalle del gasto (si aplica)
//import 'package:app_historial_vehiculo/models/vehicle.dart' as vehicle_model; // Importar el modelo Vehicle

class ChangesSavedScreen extends StatelessWidget {
  final Map<String, dynamic>? expense; // Se mantiene como Map<String, dynamic> para compatibilidad si se usa para gastos también.
                                     // Para vehículos, podrías pasar un objeto Vehicle completo si lo necesitas.
  
  const ChangesSavedScreen({super.key, this.expense}); // Modificado para aceptar expense opcional

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambios Realizados'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Decidir a dónde volver: al detalle si hay un gasto, o a la lista de gastos
            // Aquí, si se usa para vehículos, podrías volver al detalle del vehículo o a la lista general.
            if (expense != null && expense!['id'] != null) {
              // Si se pasó un "expense" (o un mapa que represente un vehículo con ID)
              // y quieres volver al detalle específico, necesitarías construir el objeto Vehicle
              // de nuevo o pasarlo directamente. Por simplicidad, volvemos a la lista.
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MyVehiclesListScreen()), // Volver a la lista general de vehículos
                (Route<dynamic> route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MyVehiclesListScreen()), // Volver a la lista general de vehículos
                (Route<dynamic> route) => false,
              );
            }
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Cambios guardados con éxito!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Los cambios han sido guardados exitosamente.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navegar a la pantalla de la lista de vehículos y limpiar la pila
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MyVehiclesListScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Volver a Vehículos',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
      // Se eliminó el BottomNavigationBar ya que las pantallas de éxito suelen no tenerlo
      // o la navegación principal se maneja en un nivel superior.
    );
  }
}
