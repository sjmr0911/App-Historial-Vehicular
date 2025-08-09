import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_historial_vehiculo/screens/Gastos/add_expense_screen.dart'; // Corrected path
import 'package:app_historial_vehiculo/screens/Gastos/expense_detail_screen.dart'; // Corrected path
import 'package:app_historial_vehiculo/screens/Gastos/no_expenses_screen.dart'; // Para cuando no hay gastos
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para la barra de navegación inferior
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Para la navegación inferior
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para la navegación inferior
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // Para la navegación inferior
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:logger/logger.dart'; // Import logger
import 'dart:async'; // Para StreamSubscription


var logger = Logger(printer: PrettyPrinter());

class ExpensesScreen extends StatefulWidget {
  // Ahora el parámetro 'expense' es opcional, lo que permite llamar a ExpensesScreen sin él.
  final Map<String, dynamic>? expense; // El '?' indica que es nullable (opcional)
  const ExpensesScreen({super.key , this.expense}); // 'required' ha sido eliminado

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int _selectedIndex = 3; // "Gastos" está en el índice 3
  List<Map<String, dynamic>> _allExpenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];
  bool _isLoading = true;
  String _filterType = 'Todos'; // 'Todos' o un tipo de gasto específico
  String _sortBy = 'Fecha'; // 'Fecha', 'Monto'

  StreamSubscription? _expenseSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> expenseTypes = [
    'Todos',
    'Combustible',
    'Mantenimiento',
    'Reparación',
    'Peaje',
    'Lavado de coche',
    'Estacionamiento',
    'Seguro',
    'Impuestos',
    'Multa',
    'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _checkUserAndFetchData();
  }

  @override
  void dispose() {
    _expenseSubscription?.cancel();
    super.dispose();
  }

  void _checkUserAndFetchData() {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Usuario no autenticado en ExpensesScreen. No se cargarán datos.');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    _fetchExpenses(user.uid);
  }

  void _fetchExpenses(String userId) {
    _expenseSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _allExpenses = snapshot.docs.map((doc) => doc.data()).toList();
        _applyFiltersAndSort();
        _isLoading = false;
      });
      logger.i('Gastos cargados: ${_allExpenses.length}');
      if (_allExpenses.isEmpty && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NoExpensesScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }, onError: (error) {
      logger.e('Error al cargar gastos: $error');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar gastos: $error')),
        );
      }
    });
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> temp = List.from(_allExpenses);

    // Aplicar filtro por tipo
    if (_filterType != 'Todos') {
      temp = temp.where((e) => e['tipo'] == _filterType).toList();
    }

    // Aplicar ordenamiento
    temp.sort((a, b) {
      if (_sortBy == 'Fecha') {
        // Asumiendo que 'fecha' es un String 'dd/MM/yyyy'
        DateTime dateA = DateFormat('dd/MM/yyyy').parse(a['fecha']);
        DateTime dateB = DateFormat('dd/MM/yyyy').parse(b['fecha']);
        return dateB.compareTo(dateA); // Más reciente primero
      } else if (_sortBy == 'Monto') {
        return (b['monto'] as double).compareTo(a['monto'] as double); // Mayor monto primero
      }
      return 0;
    });

    setState(() {
      _filteredExpenses = temp;
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
      appBar: AppBar(
        title: const Text('Gastos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1E88E5), size: 30),
            onPressed: () {
              logger.i('Botón Añadir Gasto (AppBar) presionado.');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allExpenses.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.grey,
                          size: 100,
                        ),
                        SizedBox(height: 30),
                        Text(
                          '¡Aún no tienes registros de gastos!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Añade tu primer gasto para empezar a llevar un control de tus finanzas.',
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
                              value: _filterType,
                              decoration: InputDecoration(
                                labelText: 'Filtrar por Tipo',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: expenseTypes.map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _filterType = value!;
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
                                DropdownMenuItem(value: 'Monto', child: Text('Monto')),
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
                        itemCount: _filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = _filteredExpenses[index];
                          return _buildExpenseCard(expense);
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

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    Color indicatorColor;
    switch (expense['tipo']) {
      case 'Combustible':
        indicatorColor = Colors.blue.shade700;
        break;
      case 'Mantenimiento':
        indicatorColor = Colors.green.shade700;
        break;
      case 'Reparación':
        indicatorColor = Colors.red.shade700;
        break;
      case 'Seguro':
        indicatorColor = Colors.purple.shade700;
        break;
      case 'Impuestos':
        indicatorColor = Colors.orange.shade700;
        break;
      default:
        indicatorColor = Colors.grey.shade700;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: () async {
            logger.i('Gasto "${expense['tipo']}" presionado.');
            // Navegar a la pantalla de detalle y esperar si hay cambios o eliminación
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ExpenseDetailScreen(expense: expense)),
            );
            // Si la pantalla de detalle indica una eliminación, actualizar la lista
            if (result == true) {
              // This part is handled by the StreamBuilder, so no explicit setState needed here
              // The stream will re-emit and rebuild the list automatically
            }
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
                        expense['tipo'] ?? 'N/A',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${expense['vehiculo'] ?? 'N/A'} - ${expense['fecha'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (expense['descripcion'] != null && expense['descripcion'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            expense['descripcion'],
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '\$${(expense['monto'] as double?)?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
