import 'package:flutter/material.dart';
import 'package:app_historial_vehiculo/screens/Gastos/edit_expense_screen.dart'; // Edit button
import 'package:app_historial_vehiculo/screens/Gastos/confirm_delete_expense_screen.dart'; // Delete button
import 'package:app_historial_vehiculo/screens/Gastos/expense_deleted_screen.dart'; // Para éxito de eliminación
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // Para volver a la lista de gastos
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para navegación de vehículos
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Para navegación de mantenimiento
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // Para navegación de perfil
import 'package:logger/logger.dart'; // Importa el logger
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth


var logger = Logger(printer: PrettyPrinter());

class ExpenseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> expense; // Recibe el gasto como un mapa

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late Map<String, dynamic> _currentExpense;
  int _selectedIndex = 3; // Gastos

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _currentExpense = Map<String, dynamic>.from(widget.expense); // Hacer una copia mutable
    _fetchExpenseDetails(); // Asegurarse de tener los datos más recientes
  }

  // Fetch expense details from Firestore to ensure latest data
  Future<void> _fetchExpenseDetails() async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Usuario no autenticado en ExpenseDetailScreen.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      return;
    }

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(_currentExpense['id'] as String)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _currentExpense = docSnapshot.data()!;
        });
        logger.i('Gasto cargado desde Firestore: ${_currentExpense['tipo']}');
      } else {
        logger.w('Gasto con ID ${_currentExpense['id']} no encontrado en Firestore.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gasto no encontrado.')),
          );
          Navigator.pop(context); // Go back if not found
        }
      }
    } catch (e) {
      logger.e('Error al cargar detalles del gasto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar detalles: $e')),
        );
      }
    }
  }

  // Método para manejar la navegación inferior
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Widget screenToNavigate;
    switch (index) {
      case 0: screenToNavigate = const HomeScreen(); break;
      case 1: screenToNavigate = const MyVehiclesListScreen(); break;
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

  // Función para eliminar gasto
  Future<void> _deleteExpense() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      logger.e('Error: Usuario no autenticado al intentar eliminar gasto.');
      return;
    }

    final bool? confirmDelete = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ConfirmDeleteExpenseScreen(expense: _currentExpense)),
    );

    if (confirmDelete == true) {
      // Muestra un indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminando gasto...')),
        );
      }

      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .doc(_currentExpense['id'] as String)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ExpenseDeletedScreen(expense: _currentExpense)),
            (Route<dynamic> route) => false,
          );
          logger.i('Gasto "${_currentExpense['tipo']}" eliminado exitosamente.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar gasto: $e')),
          );
        }
        logger.e('Error al eliminar gasto: $e');
      }
    } else {
      logger.i('Eliminación de gasto cancelada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Gasto'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
            onPressed: () async {
              logger.i('Botón Editar Gasto presionado.');
              final updatedExpense = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditExpenseScreen(expense: _currentExpense)),
              );
              if (updatedExpense != null && updatedExpense is Map<String, dynamic>) {
                setState(() {
                  _currentExpense = updatedExpense;
                });
                logger.i('Gasto actualizado desde EditExpenseScreen.');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteExpense,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del Gasto',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 15),
                    _buildDetailRow('Tipo de Gasto', _currentExpense['tipo'] ?? 'N/A'),
                    const Divider(height: 20, thickness: 0.5),
                    _buildDetailRow('Vehículo', _currentExpense['vehiculo'] ?? 'N/A'),
                    const Divider(height: 20, thickness: 0.5),
                    _buildDetailRow('Fecha', _currentExpense['fecha'] ?? 'N/A'),
                    const Divider(height: 20, thickness: 0.5),
                    _buildDetailRow('Monto', '\$${(_currentExpense['monto'] as double?)?.toStringAsFixed(2) ?? '0.00'}'),
                    const Divider(height: 20, thickness: 0.5),
                    _buildDetailRow('Método de Pago', _currentExpense['metodoPago'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentExpense['descripcion'] ?? 'No hay descripción adicional.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Vehículos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Mantenimiento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Gastos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
