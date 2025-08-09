// lib/maintenance_list_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import 'package:app_historial_vehiculo/models/maintenance.dart'; // Importa la clase Maintenance desde el modelo central
import 'package:app_historial_vehiculo/screens/Mantenimiento/add_maintenance_screen.dart'; // Para añadir nuevo mantenimiento
import 'package:app_historial_vehiculo/screens/Mantenimiento/Detail_mantenance_screen.dart'; // Para ver detalles
import 'package:app_historial_vehiculo/screens/Mantenimiento/no_maintenance_screen.dart'; // Para el caso de no tener mantenimientos
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // For BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // For BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // For BottomNavigationBar
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'dart:async'; // Para StreamSubscription


var logger = Logger(printer: PrettyPrinter());

class MaintenanceListScreen extends StatefulWidget {
  final String? deletedMaintenanceId; // Para saber si se eliminó un mantenimiento y actualizar la lista

  const MaintenanceListScreen({super.key, this.deletedMaintenanceId});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  int _selectedIndex = 2; // "Mantenimiento" está en el índice 2
  List<Maintenance> _allMaintenances = [];
  List<Maintenance> _filteredMaintenances = [];
  bool _isLoading = true;
  String _filterStatus = 'Todos'; // 'Todos', 'Pendiente', 'Completado'
  String _sortBy = 'Fecha'; // 'Fecha', 'Costo'

  StreamSubscription? _maintenanceSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkUserAndFetchData();
  }

  @override
  void dispose() {
    _maintenanceSubscription?.cancel();
    super.dispose();
  }

  void _checkUserAndFetchData() {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Usuario no autenticado en MaintenanceListScreen. No se cargarán datos.');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    _fetchMaintenances(user.uid);
  }

  void _fetchMaintenances(String userId) {
    _maintenanceSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('maintenances')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _allMaintenances = snapshot.docs.map((doc) => Maintenance.fromFirestore(doc)).toList();
        _applyFiltersAndSort();
        _isLoading = false;
      });
      logger.i('Mantenimientos cargados: ${_allMaintenances.length}');
      if (_allMaintenances.isEmpty && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NoMaintenanceScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }, onError: (error) {
      logger.e('Error al cargar mantenimientos: $error');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar mantenimientos: $error')),
        );
      }
    });
  }

  void _applyFiltersAndSort() {
    List<Maintenance> temp = List.from(_allMaintenances);

    // Aplicar filtro por estado
    if (_filterStatus != 'Todos') {
      temp = temp.where((m) => m.estado == _filterStatus).toList();
    }

    // Aplicar ordenamiento
    temp.sort((a, b) {
      if (_sortBy == 'Fecha') {
        return b.fecha.compareTo(a.fecha); // Más reciente primero
      } else if (_sortBy == 'Costo') {
        return b.costo.compareTo(a.costo); // Mayor costo primero
      }
      return 0;
    });

    setState(() {
      _filteredMaintenances = temp;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
      appBar: AppBar(
        title: const Text('Mantenimiento'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1E88E5), size: 30),
            onPressed: () {
              logger.i('Botón Añadir Mantenimiento (AppBar) presionado.');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMaintenanceScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allMaintenances.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.build_outlined,
                          color: Colors.grey,
                          size: 100,
                        ),
                        SizedBox(height: 30),
                        Text(
                          '¡Aún no tienes registros de mantenimiento!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Añade tu primer registro para empezar a gestionarlo.',
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filterStatus,
                              decoration: InputDecoration(
                                labelText: 'Filtrar por Estado',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                                DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                                DropdownMenuItem(value: 'Completado', child: Text('Completado')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _filterStatus = value!;
                                  _applyFiltersAndSort();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortBy,
                              decoration: InputDecoration(
                                labelText: 'Ordenar por',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Fecha', child: Text('Fecha')),
                                DropdownMenuItem(value: 'Costo', child: Text('Costo')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _sortBy = value!;
                                  _applyFiltersAndSort();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredMaintenances.length,
                        itemBuilder: (context, index) {
                          final maintenance = _filteredMaintenances[index];
                          return _buildMaintenanceCard(maintenance);
                        },
                      ),
                    ),
                  ],
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

  Widget _buildMaintenanceCard(Maintenance maintenance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 1,
      child: InkWell(
        onTap: () {
          logger.i('Mantenimiento "${maintenance.tipoMantenimiento}" presionado.');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MaintenanceDetailScreen(id: maintenance.id, maintenance: maintenance)),
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
                  color: maintenance.estado == 'Pendiente' ? Colors.orange : Colors.green,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maintenance.tipoMantenimiento,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${maintenance.vehiculo} - ${DateFormat('dd/MM/yyyy').format(maintenance.fecha)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: maintenance.estado == 'Pendiente' ? Colors.orange.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        maintenance.estado,
                        style: TextStyle(
                          fontSize: 12,
                          color: maintenance.estado == 'Pendiente' ? Colors.orange.shade800 : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (maintenance.costo > 0)
                Text(
                  '\$${maintenance.costo.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                )
              else
                Text(
                  'Gratis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
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
