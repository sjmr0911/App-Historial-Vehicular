import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/models/maintenance.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/edit_maintenance_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/delete_maintenance_confirmation_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';

// Importaciones de Firebase para Firestore y Auth
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

var logger = Logger(printer: PrettyPrinter());

class MaintenanceDetailScreen extends StatefulWidget {
  final String id;
  final Maintenance? maintenance;

  const MaintenanceDetailScreen({super.key, required this.id, this.maintenance});

  @override
  State<MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  Maintenance? _currentMaintenance;
  int _selectedIndex = 2;

  // Variables de entorno para Firebase
  final String _firebaseConfigJson = const String.fromEnvironment('__firebase_config', defaultValue: '{}');
  final String _initialAuthToken = const String.fromEnvironment('__initial_auth_token', defaultValue: '');
  
  // Instancias de Firebase
  FirebaseFirestore? db;
  FirebaseAuth? auth;
  String? userId;
  bool _isFirebaseReady = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  // Método para inicializar Firebase y autenticar al usuario
  Future<void> _initializeFirebase() async {
    try {
      // Verifica si la aplicación de Firebase ya ha sido inicializada
      if (Firebase.apps.isEmpty) {
        final Map<String, dynamic> firebaseConfig = json.decode(_firebaseConfigJson);
        
        FirebaseApp app = await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: firebaseConfig['apiKey'] ?? '',
            appId: firebaseConfig['appId'] ?? '',
            messagingSenderId: firebaseConfig['messagingSenderId'] ?? '',
            projectId: firebaseConfig['projectId'] ?? '',
            storageBucket: firebaseConfig['storageBucket'] ?? '',
          ),
        );
        auth = FirebaseAuth.instanceFor(app: app);
        db = FirebaseFirestore.instanceFor(app: app);
      } else {
        // Si ya existe, simplemente usa la instancia por defecto
        auth = FirebaseAuth.instance;
        db = FirebaseFirestore.instance;
      }
      
      // Lógica de autenticación con un mecanismo de respaldo
      if (auth != null) {
        try {
          if (_initialAuthToken.isNotEmpty) {
            await auth!.signInWithCustomToken(_initialAuthToken);
            logger.i('Autenticación exitosa con token personalizado.');
          } else {
            await auth!.signInAnonymously();
            logger.i('Autenticación exitosa de forma anónima.');
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'admin-restricted-operation') {
            logger.w('La operación de token personalizado está restringida, intentando con autenticación anónima.');
            try {
              await auth!.signInAnonymously();
              logger.i('Autenticación exitosa de forma anónima (fallback).');
            } catch (e) {
              logger.e('Error en la autenticación anónima de respaldo: $e');
            }
          } else {
            logger.e('Error de autenticación desconocido: $e');
          }
        }
      }

      // Obtiene el ID del usuario actual
      userId = auth?.currentUser?.uid;
      logger.i('User ID: $userId');

      setState(() {
        _isFirebaseReady = true;
      });

      // Llama a _fetchMaintenanceDetails solo si el widget no tiene un objeto de mantenimiento
      if (widget.maintenance == null) {
        _fetchMaintenanceDetails();
      } else {
        _currentMaintenance = widget.maintenance;
        logger.i('Mantenimiento cargado desde el objeto pasado: ${_currentMaintenance?.tipoMantenimiento}');
      }
    } catch (e) {
      logger.e('Error inicializando Firebase: $e');
    }
  }

  Future<void> _fetchMaintenanceDetails() async {
    if (!_isFirebaseReady || db == null || userId == null) {
      logger.w('Firebase no está listo. No se puede cargar el mantenimiento.');
      return;
    }

    try {
      // 🔄 CÓDIGO CORREGIDO: La ruta ahora es más simple
      final docSnapshot = await db!
          .collection('users')
          .doc(userId)
          .collection('maintenances')
          .doc(widget.id)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _currentMaintenance = Maintenance.fromFirestore(docSnapshot);
        });
        logger.i('Mantenimiento cargado desde Firestore: ${_currentMaintenance?.tipoMantenimiento}');
      } else {
        logger.w('Mantenimiento con ID ${widget.id} no encontrado en Firestore.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mantenimiento no encontrado.')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      logger.e('Error al cargar detalles del mantenimiento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar detalles: $e')),
        );
      }
    }
  }
  
  // Método para crear un documento de notificación en Firestore
  Future<void> _createSavedNotification(String title, IconData iconData) async {
    if (!_isFirebaseReady || db == null || userId == null) {
      logger.w('Firebase no está listo. No se puede crear la notificación.');
      return;
    }

    try {
      // 🔄 CÓDIGO CORREGIDO: La ruta ahora es más simple
      final docRef = await db!
          .collection('users')
          .doc(userId!)
          .collection('notifications')
          .add({
        'title': title,
        'icon': iconData.codePoint,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      logger.i(
          'Notificación "$title" creada exitosamente con ID: ${docRef.id}');
    } catch (e) {
      logger.e('Error al crear la notificación: $e');
    }
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

  Future<void> _markAsCompleted() async {
    if (_currentMaintenance == null || !_isFirebaseReady || db == null || userId == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marcando como completado...')),
      );
    }

    try {
      // 🔄 CÓDIGO CORREGIDO: La ruta ahora es más simple
      await db!
          .collection('users')
          .doc(userId)
          .collection('maintenances')
          .doc(_currentMaintenance!.id)
          .update({'estado': 'Completado'});

      _createSavedNotification('Mantenimiento completado', Icons.check_circle_outline);

      setState(() {
        _currentMaintenance = _currentMaintenance!.copyWith(estado: 'Completado');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.pop(context);
        logger.i('Mantenimiento "${_currentMaintenance!.tipoMantenimiento}" marcado como completado y se ha regresado a la pantalla de detalle.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al marcar como completado: $e')),
        );
      }
      logger.e('Error al marcar mantenimiento como completado: $e');
    }
  }

  Future<void> _deleteMaintenance() async {
    if (_currentMaintenance == null || !_isFirebaseReady || db == null || userId == null) return;

    final bool? confirmDelete = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeleteMaintenanceConfirmationScreen(maintenance: _currentMaintenance!.toFirestore())),
    );

    if (confirmDelete == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminando mantenimiento...')),
        );
      }

      try {
        // 🔄 CÓDIGO CORREGIDO: La ruta ahora es más simple
        await db!
            .collection('users')
            .doc(userId)
            .collection('maintenances')
            .doc(_currentMaintenance!.id)
            .delete();
            
        _createSavedNotification('Mantenimiento eliminado', Icons.delete_forever);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MaintenanceListScreen(deletedMaintenanceId: _currentMaintenance!.id)),
            (Route<dynamic> route) => false,
          );
          logger.i('Mantenimiento "${_currentMaintenance!.tipoMantenimiento}" eliminado exitosamente.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar mantenimiento: $e')),
          );
        }
        logger.e('Error al eliminar mantenimiento: $e');
      }
    } else {
      logger.i('Eliminación de mantenimiento cancelada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMaintenance == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Detalle de Mantenimiento',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Tipo de\nMantenimiento', _currentMaintenance!.tipoMantenimiento),
                    const Divider(height: 20, thickness: 0.5),
                    _buildInfoRow('Vehículo', _currentMaintenance!.vehiculo),
                    const Divider(height: 20, thickness: 0.5),
                    _buildInfoRow('Fecha', DateFormat('dd/MM/yyyy').format(_currentMaintenance!.fecha)),
                    const Divider(height: 20, thickness: 0.5),
                    _buildInfoRow('Kilometraje', '${_currentMaintenance!.kilometraje} km'),
                    const Divider(height: 20, thickness: 0.5),
                    _buildInfoRow('Costo', '\$${_currentMaintenance!.costo.toStringAsFixed(2)}', isPrice: true),
                    const Divider(height: 20, thickness: 0.5),
                    _buildInfoRow('Estado', _currentMaintenance!.estado, isStatus: true),
                    const SizedBox(height: 20),
                    const Text(
                      'Descripción',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentMaintenance!.descripcion ?? 'No hay descripción adicional.',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _currentMaintenance == null ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditMaintenanceScreen(maintenance: _currentMaintenance!)),
                        );
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        'Editar',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _currentMaintenance == null ? null : _deleteMaintenance,
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text(
                        'Eliminar',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_currentMaintenance!.estado == 'Pendiente') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _markAsCompleted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Marcar como Completado',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
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

  Widget _buildInfoRow(String label, String value, {bool isStatus = false, bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: isStatus
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: value == 'Pendiente' ? Colors.orange[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          color: value == 'Pendiente' ? Colors.orange[700] : Colors.green[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: isPrice ? const Color(0xFF1E88E5) : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}