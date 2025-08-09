// lib/my_vehicles_list_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Importar las clases de modelo desde sus archivos dedicados
import 'package:app_historial_vehiculo/models/reminder.dart';
import 'package:app_historial_vehiculo/models/vehicle.dart';

// Importar las pantallas necesarias para la navegación
import 'package:app_historial_vehiculo/screens/Vehiculos/add_vehicle_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/vehicle_detail_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/no_vehicles_screen.dart';

// Importar pantallas de otras secciones para el BottomNavigationBar y acciones rápidas
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/add_reminder_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_detail_screen.dart';


var logger = Logger(printer: PrettyPrinter());

class MyVehiclesListScreen extends StatefulWidget {
  final bool hasVehicle;

  const MyVehiclesListScreen({super.key, this.hasVehicle = false});

  @override
  State<MyVehiclesListScreen> createState() => _MyVehiclesListScreenState();
}

class _MyVehiclesListScreenState extends State<MyVehiclesListScreen> {
  int _selectedIndex = 1;
  List<Vehicle> _vehicles = [];
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  StreamSubscription? _vehiclesSubscription;
  StreamSubscription? _remindersSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkUserAndFetchData();
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    _remindersSubscription?.cancel();
    super.dispose();
  }

  void _checkUserAndFetchData() {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Usuario no autenticado en MyVehiclesListScreen. No se cargarán datos.');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    _fetchVehicles(user.uid);
    _fetchReminders(user.uid);
  }

  void _fetchVehicles(String userId) {
    _vehiclesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _vehicles = snapshot.docs.map((doc) => Vehicle.fromFirestore(doc)).toList();
        _isLoading = false;
      });
      logger.i('Vehículos cargados: ${_vehicles.length}');
      if (_vehicles.isEmpty && !widget.hasVehicle) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const NoVehiclesScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    }, onError: (error) {
      logger.e('Error al cargar vehículos: $error');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar vehículos: $error')),
        );
      }
    });
  }

  void _fetchReminders(String userId) {
    _remindersSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('reminders')
        .where('status', isEqualTo: 'Pendiente')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _reminders = snapshot.docs.map((doc) => Reminder.fromFirestore(doc)).toList();
        _reminders.sort((a, b) {
          final dateA = DateTime.tryParse('${a.date} ${a.time}');
          final dateB = DateTime.tryParse('${b.date} ${b.time}');
          if (dateA != null && dateB != null) {
            return dateA.compareTo(dateB);
          }
          return 0;
        });
      });
      logger.i('Recordatorios cargados: ${_reminders.length}');
    }, onError: (error) {
      logger.e('Error al cargar recordatorios: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar recordatorios: $error')),
        );
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
        break;
      case 1:
        return;
      case 2:
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MaintenanceListScreen()), (route) => false);
        break;
      case 3:
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ExpensesScreen()), (route) => false);
        break;
      case 4:
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ProfileScreen()), (route) => false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Vehículos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1E88E5), size: 30),
            onPressed: () {
              logger.i('Botón Añadir Vehículo (AppBar) presionado.');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          color: Colors.grey,
                          size: 100,
                        ),
                        SizedBox(height: 30),
                        Text(
                          '¡Aún no tienes vehículos!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Añade tu primer vehículo para empezar a gestionarlo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado "Mis Vehículos"
                      const Text(
                        'Mis Vehículos',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Lista de Vehículos
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _vehicles[index];
                          return _buildVehicleCard(vehicle);
                        },
                      ),
                      const SizedBox(height: 30),

                      // === INICIO DEL CAMBIO ===
                      // Encabezado con el botón para añadir recordatorio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recordatorios',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF1E88E5), size: 30),
                            onPressed: () {
                              logger.i('Botón Añadir Recordatorio presionado.');
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddReminderScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                      // === FIN DEL CAMBIO ===

                      const SizedBox(height: 16),
                      // Lista de Recordatorios Pendientes
                      _reminders.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No hay recordatorios pendientes.',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _reminders.length > 3 ? 3 : _reminders.length,
                              itemBuilder: (context, index) {
                                final reminder = _reminders[index];
                                return _buildReminderCard(reminder);
                              },
                            ),
                      if (_reminders.length > 3)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              logger.i('Ver todos los recordatorios presionado.');
                              // En un futuro, podrías navegar a una pantalla con todos los recordatorios
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => const AllRemindersScreen()));
                            },
                            child: const Text(
                              'Ver todos los recordatorios',
                              style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
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
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 1,
      child: InkWell(
        onTap: () {
          logger.i('Vehículo "${vehicle.name} ${vehicle.brandModel}" presionado.');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VehicleDetailScreen(vehicle: vehicle)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  vehicle.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: Icon(Icons.directions_car, color: Colors.grey[600], size: 40),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.name} ${vehicle.brandModel}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${vehicle.year} | ${vehicle.plate}',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    Text(
                      '${vehicle.mileage} km',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    Color indicatorColor = reminder.status == 'Pendiente' ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 1,
      child: InkWell(
        onTap: () {
          logger.i('Recordatorio "${reminder.title}" presionado.');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReminderDetailScreen(reminder: reminder)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 50,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${reminder.vehicle} - ${reminder.date}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                reminder.status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: indicatorColor == Colors.orange ? Colors.orange[700] : Colors.green[700],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}