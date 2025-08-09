// lib/screens/Vehiculos/vehicle_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:app_historial_vehiculo/models/vehicle.dart' as vehicle_model; // Usar prefijo para el modelo Vehicle
import 'package:app_historial_vehiculo/screens/Vehiculos/edit_vehicle_screen.dart';

// Importaciones directas para las "Secciones Relacionadas"
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/documents_screen.dart';
//import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para Recordatorios, que redirige a MyVehiclesListScreen
import 'package:app_historial_vehiculo/screens/Recordatorios/add_reminder_screen.dart'; // Para añadir recordatorio
import 'package:logger/logger.dart'; // Import logger

var logger = Logger(printer: PrettyPrinter());


class VehicleDetailScreen extends StatefulWidget {
  final vehicle_model.Vehicle vehicle; // Usar el prefijo para el tipo de la propiedad

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late vehicle_model.Vehicle _currentVehicle; // Usar el prefijo para el tipo de la variable de estado

  @override
  void initState() {
    super.initState();
    _currentVehicle = widget.vehicle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Vehículo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context); // Vuelve a la pantalla anterior
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
            onPressed: () async {
              logger.i('Botón Editar Vehículo presionado.');
              // Navegar a la pantalla de edición, pasando el vehículo actual
              final updatedVehicle = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditVehicleScreen(vehicle: _currentVehicle),
                ),
              );

              // Si se devuelve un vehículo actualizado, actualiza el estado
              if (updatedVehicle != null && updatedVehicle is vehicle_model.Vehicle) {
                setState(() {
                  _currentVehicle = updatedVehicle;
                });
                logger.i('Vehículo actualizado desde EditVehicleScreen.');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: _currentVehicle.imageUrl.isNotEmpty
                    ? Image.network(
                        _currentVehicle.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey[200],
                            child: Icon(Icons.directions_car, color: Colors.grey[600], size: 80),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[200],
                        child: Icon(Icons.directions_car, color: Colors.grey[600], size: 80),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // Reemplazo del título
            Center(
              child: Text(
                _currentVehicle.brandModel,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 24),

            // Tarjeta de Información General
            _buildInfoCard(
              title: 'Información General',
              children: [
                _buildInfoRow('Marca', _currentVehicle.name),
                _buildInfoRow('Modelo', _currentVehicle.brandModel),
                _buildInfoRow('Año', _currentVehicle.year.toString()),
                _buildInfoRow('Color', _currentVehicle.color), // Nuevo campo para el color
              ],
            ),
            const SizedBox(height: 16),

            // Tarjeta de Registro
            _buildInfoCard(
              title: 'Registro',
              children: [
                _buildInfoRow('Placa', _currentVehicle.plate),
              ],
            ),
            const SizedBox(height: 16),

            // Tarjeta de Kilometraje
            _buildInfoCard(
              title: 'Kilometraje',
              children: [
                _buildInfoRow('Kilometraje actual', '${_currentVehicle.mileage} km'),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Secciones Relacionadas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildRelatedSectionTile(
              icon: Icons.build,
              title: 'Mantenimiento',
              onTap: () {
                logger.i('Navegando a Mantenimiento para ${_currentVehicle.name}.');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MaintenanceListScreen()),
                );
              },
            ),
            _buildRelatedSectionTile(
              icon: Icons.attach_money,
              title: 'Gastos',
              onTap: () {
                logger.i('Navegando a Gastos para ${_currentVehicle.name}.');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpensesScreen()),
                );
              },
            ),
            _buildRelatedSectionTile(
              icon: Icons.notifications_active,
              title: 'Recordatorios',
              onTap: () {
                logger.i('Navegando a Añadir Recordatorio para ${_currentVehicle.name}.');
                // Podrías pasar el vehículo para pre-seleccionar en el formulario de recordatorio
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddReminderScreen()),
                );
              },
            ),
            _buildRelatedSectionTile(
              icon: Icons.description,
              title: 'Documentos',
              onTap: () {
                logger.i('Navegando a Documentos para ${_currentVehicle.name}.');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DocumentsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Nuevo widget para crear tarjetas de información
  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedSectionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue, size: 28),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
