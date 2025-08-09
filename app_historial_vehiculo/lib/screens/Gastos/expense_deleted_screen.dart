import 'package:flutter/material.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

class ExpenseDeletedScreen extends StatefulWidget {
  final Map<String, dynamic> expense;

  const ExpenseDeletedScreen({super.key, required this.expense});

  @override
  State<ExpenseDeletedScreen> createState() => _ExpenseDeletedScreenState();
}

class _ExpenseDeletedScreenState extends State<ExpenseDeletedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _createDeletedNotification();
  }

  // 🔄 MODIFICADO: Método para crear una notificación de eliminación con detalles y ícono
  Future<void> _createDeletedNotification() async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('No se pudo crear la notificación: Usuario no autenticado.');
      return;
    }

    // Usar la descripción o el tipo de gasto si la descripción es nula
    final expenseDescription = widget.expense['descripcion'] ?? widget.expense['tipo'] ?? 'un gasto';
    final vehicleName = widget.expense['vehiculo'] ?? 'un vehículo';

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        // 🔄 MODIFICADO: Título más específico
        'title': 'Gasto eliminado: $expenseDescription',
        // 🔄 MODIFICADO: Subtítulo con el nombre del vehículo
        'subtitle': 'Se ha eliminado el gasto "$expenseDescription" para el vehículo "$vehicleName".',
        'icon': Icons.delete_forever.codePoint, // 🔄 MODIFICADO: Ícono de eliminar
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      logger.i('Notificación de gasto eliminado para $expenseDescription en $vehicleName creada exitosamente.');
    } catch (e) {
      logger.e('Error al crear la notificación de gasto eliminado: $e');
    }
  }

  void _handleBottomNavigation(BuildContext context, int index) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gasto Eliminado'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cancel_outlined,
              color: Colors.red,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Gasto eliminado con éxito!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'El gasto "${widget.expense['descripcion'] ?? widget.expense['tipo'] ?? 'N/A'}" ha sido eliminado permanentemente.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpensesScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Volver a Gastos',
                style: TextStyle(fontSize: 18),
              ),
            ),
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
        currentIndex: 3,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          _handleBottomNavigation(context, index);
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
