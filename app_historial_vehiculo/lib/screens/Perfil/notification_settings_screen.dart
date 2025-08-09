// lib/screens/Perfil/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';


var logger = Logger(printer: PrettyPrinter());

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Estados de los toggles
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;
  bool _maintenanceRemindersEnabled = true;
  bool _expenseAlertsEnabled = true;
  bool _documentUpdatesEnabled = false;
  bool _offersNewsEnabled = false;

  int _selectedIndex = 4;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Usuario no autenticado. No se cargarán las configuraciones de notificación.');
      return;
    }

    try {
      final docSnapshot = await _firestore.collection('users').doc(user.uid).collection('settings').doc('notifications').get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        setState(() {
          _pushNotificationsEnabled = data?['pushNotificationsEnabled'] ?? true;
          _emailNotificationsEnabled = data?['emailNotificationsEnabled'] ?? false;
          _maintenanceRemindersEnabled = data?['maintenanceRemindersEnabled'] ?? true;
          _expenseAlertsEnabled = data?['expenseAlertsEnabled'] ?? true;
          _documentUpdatesEnabled = data?['documentUpdatesEnabled'] ?? false;
          _offersNewsEnabled = data?['offersNewsEnabled'] ?? false;
        });
        logger.i('Configuraciones de notificación cargadas.');
      } else {
        logger.i('No se encontraron configuraciones de notificación existentes. Usando valores por defecto.');
      }
    } catch (e) {
      logger.e('Error al cargar configuraciones de notificación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar configuraciones: $e')),
        );
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      return;
    }

    // Muestra un indicador de carga
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardando configuraciones...')),
      );
    }

    try {
      await _firestore.collection('users').doc(user.uid).collection('settings').doc('notifications').set({
        'pushNotificationsEnabled': _pushNotificationsEnabled,
        'emailNotificationsEnabled': _emailNotificationsEnabled,
        'maintenanceRemindersEnabled': _maintenanceRemindersEnabled,
        'expenseAlertsEnabled': _expenseAlertsEnabled,
        'documentUpdatesEnabled': _documentUpdatesEnabled,
        'offersNewsEnabled': _offersNewsEnabled,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuraciones guardadas con éxito.')),
        );
        Navigator.pop(context); // Vuelve a la pantalla anterior
      }
      logger.i('Configuraciones de notificación guardadas.');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar configuraciones: $e')),
        );
      }
      logger.e('Error al guardar configuraciones de notificación: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    logger.i('Bottom navigation tapped on NotificationSettingsScreen: ${_getBottomNavItemName(index)} (índice: $index)');
    _handleBottomNavigation(index);
  }

  String _getBottomNavItemName(int index) {
    switch (index) {
      case 0: return 'Inicio';
      case 1: return 'Vehículos';
      case 2: return 'Mantenimiento';
      case 3: return 'Gastos';
      case 4: return 'Perfil';
      default: return '';
    }
  }

  void _handleBottomNavigation(int index) {
    Widget screenToNavigate;
    switch (index) {
      case 0: screenToNavigate = const HomeScreen(); break;
      case 1: screenToNavigate = const MyVehiclesListScreen(); break;
      case 2: screenToNavigate = const MaintenanceListScreen(); break;
      case 3: screenToNavigate = const ExpensesScreen(); break;
      case 4: screenToNavigate = const ProfileScreen(); break; // Ya estamos en Perfil (o una sub-pantalla)
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () {
            logger.i('Volver desde Configuración de Notificaciones');
            Navigator.pop(context); // Vuelve a ProfileScreen
          },
        ),
        title: const Text(
          'Configuración de Notificaciones',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('Notificaciones Generales'),
            _buildToggleTile(
              icon: Icons.notifications_active_outlined,
              title: 'Notificaciones Push',
              value: _pushNotificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _pushNotificationsEnabled = value;
                });
                logger.i('Notificaciones Push: $value');
              },
            ),
            _buildToggleTile(
              icon: Icons.email_outlined,
              title: 'Notificaciones por Correo Electrónico',
              value: _emailNotificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _emailNotificationsEnabled = value;
                });
                logger.i('Notificaciones por Correo Electrónico: $value');
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Alertas Específicas'),
            _buildToggleTile(
              icon: Icons.build_outlined,
              title: 'Recordatorios de Mantenimiento',
              value: _maintenanceRemindersEnabled,
              onChanged: (bool value) {
                setState(() {
                  _maintenanceRemindersEnabled = value;
                });
                logger.i('Recordatorios de Mantenimiento: $value');
              },
            ),
            _buildToggleTile(
              icon: Icons.attach_money_outlined,
              title: 'Alertas de Gastos',
              value: _expenseAlertsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _expenseAlertsEnabled = value;
                });
                logger.i('Alertas de Gastos: $value');
              },
            ),
            _buildToggleTile(
              icon: Icons.description_outlined,
              title: 'Actualizaciones de Documentos',
              value: _documentUpdatesEnabled,
              onChanged: (bool value) {
                setState(() {
                  _documentUpdatesEnabled = value;
                });
                logger.i('Actualizaciones de Documentos: $value');
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Promociones y Noticias'),
            _buildToggleTile(
              icon: Icons.campaign_outlined,
              title: 'Ofertas y Noticias',
              value: _offersNewsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _offersNewsEnabled = value;
                });
                logger.i('Ofertas y Noticias: $value');
              },
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _saveNotificationSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
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
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(0x1f),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF1E88E5), // Color cuando está activado
            ),
          ],
        ),
      ),
    );
  }
}
