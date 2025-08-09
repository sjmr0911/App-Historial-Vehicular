import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Importaciones de pantallas principales
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/add_expense_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/add_reminder_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/documents_screen.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/notifications_screen.dart';
//import 'package:app_historial_vehiculo/screens/Vehiculos/add_vehicle_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/vehicle_detail_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/Detail_mantenance_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_detail_screen.dart';

// Asegúrate de que tus modelos (Reminder, Vehicle, Maintenance, etc.) estén en lib/models/
import 'package:app_historial_vehiculo/models/vehicle.dart';
import 'package:app_historial_vehiculo/models/maintenance.dart';
import 'package:app_historial_vehiculo/models/reminder.dart';

var logger = Logger(printer: PrettyPrinter());

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Vehicle> _vehicles = [];
  List<Maintenance> _upcomingMaintenances = [];
  List<Reminder> _upcomingReminders = [];
  int _notificationCount = 0;

  StreamSubscription? _vehiclesSubscription;
  StreamSubscription? _maintenancesSubscription;
  StreamSubscription? _remindersSubscription;
  StreamSubscription? _notificationsSubscription;

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
    _maintenancesSubscription?.cancel();
    _remindersSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _checkUserAndFetchData() {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Usuario no autenticado en HomeScreen. No se cargarán datos.');
      return;
    }
    _fetchVehicles(user.uid);
    _fetchUpcomingMaintenances(user.uid);
    _fetchUpcomingReminders(user.uid);
    _fetchNotificationsCount(user.uid);
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
      });
      logger.i('Vehículos cargados: ${_vehicles.length}');
    }, onError: (error) {
      logger.e('Error al cargar vehículos: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar vehículos: $error')),
        );
      }
    });
  }

  void _fetchNotificationsCount(String userId) {
    _notificationsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _notificationCount = snapshot.docs.length;
      });
      logger.i('Notificaciones pendientes: $_notificationCount');
    }, onError: (error) {
      logger.e('Error al cargar notificaciones: $error');
    });
  }

  void _fetchUpcomingMaintenances(String userId) {
    _maintenancesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('maintenances')
        .where('estado', isEqualTo: 'Pendiente')
        .limit(3)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _upcomingMaintenances = snapshot.docs.map((doc) => Maintenance.fromFirestore(doc)).toList();
        _upcomingMaintenances.sort((a, b) => a.fecha.compareTo(b.fecha));
      });
      logger.i('Próximos mantenimientos cargados: ${_upcomingMaintenances.length}');
    }, onError: (error) {
      logger.e('Error al cargar próximos mantenimientos: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar próximos mantenimientos: $error')),
        );
      }
    });
  }

  void _fetchUpcomingReminders(String userId) {
    _remindersSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('reminders')
        .where('status', isEqualTo: 'Pendiente')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _upcomingReminders = snapshot.docs.map((doc) => Reminder.fromFirestore(doc)).toList();
        _upcomingReminders.sort((a, b) {
          final dateA = DateTime.tryParse('${a.date} ${a.time}');
          final dateB = DateTime.tryParse('${b.date} ${b.time}');
          if (dateA != null && dateB != null) {
            return dateA.compareTo(dateB);
          }
          return 0;
        });
        _upcomingReminders = _upcomingReminders.take(3).toList();
      });
      logger.i('Próximos recordatorios cargados: ${_upcomingReminders.length}');
    }, onError: (error) {
      logger.e('Error al cargar próximos recordatorios: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar próximos recordatorios: $error')),
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
        return;
      case 1:
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MyVehiclesListScreen()), (route) => false);
        break;
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
        title: const Text('Mi Historial de Vehículos'),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black87, size: 28),
                onPressed: () {
                  logger.i('Botón Notificaciones presionado.');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Acciones Rápidas
            const Text(
              'Acciones Rápidas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildQuickActionCard(
                  icon: Icons.add,
                  text: 'Añadir Gasto',
                  onTap: () {
                    logger.i('Acción Rápida: Añadir Gasto');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
                    );
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.calendar_today,
                  text: 'Programar Mantenimiento',
                  onTap: () {
                    logger.i('Acción Rápida: Programar Mantenimiento');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MaintenanceListScreen()),
                    );
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.description,
                  text: 'Ver Documentos',
                  onTap: () {
                    logger.i('Acción Rápida: Ver Documentos');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DocumentsScreen()),
                    );
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.notifications,
                  text: 'Añadir Recordatorio',
                  onTap: () {
                    logger.i('Acción Rápida: Añadir Recordatorio');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Sección de Tus Vehículos
            const Text(
              'Tus Vehículos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _vehicles.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No tienes vehículos registrados. ¡Añade uno para empezar!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _vehicles.length > 2 ? 2 : _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      return _buildVehicleCard(vehicle);
                    },
                  ),
            if (_vehicles.length > 2)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    logger.i('Ver todos los vehículos presionado.');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyVehiclesListScreen()),
                    );
                  },
                  child: const Text(
                    'Ver todos los vehículos',
                    style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 30),

            // Sección de Próximos Mantenimientos
            const Text(
              'Próximos Mantenimientos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _upcomingMaintenances.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No hay mantenimientos pendientes.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _upcomingMaintenances.length,
                    itemBuilder: (context, index) {
                      final maintenance = _upcomingMaintenances[index];
                      return _buildUpcomingCard(
                        maintenance.tipoMantenimiento,
                        '${maintenance.vehiculo} - ${maintenance.fecha.day}/${maintenance.fecha.month}/${maintenance.fecha.year}',
                        Icons.build,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MaintenanceDetailScreen(id: maintenance.id, maintenance: maintenance)),
                          );
                        }
                      );
                    },
                  ),
            const SizedBox(height: 30),

            // Sección de Recordatorios Pendientes
            const Text(
              'Recordatorios Pendientes',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _upcomingReminders.isEmpty
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
                    itemCount: _upcomingReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _upcomingReminders[index];
                      return _buildUpcomingCard(
                        reminder.title,
                        '${reminder.vehicle} - ${reminder.date} ${reminder.time}',
                        Icons.notifications_active,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ReminderDetailScreen(reminder: reminder)),
                          );
                        }
                      );
                    },
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

  Widget _buildQuickActionCard({required IconData icon, required String text, required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      color: const Color(0xFFE8F0FE),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFF1967D2),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1967D2),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
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
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: Icon(Icons.directions_car, color: Colors.grey[600], size: 30),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${vehicle.year} | ${vehicle.plate}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(String title, String value, IconData icon, {required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}