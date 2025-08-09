import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:timeago/timeago.dart' as timeago;

// Importaciones de pantallas principales para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

// Modelo de datos para una notificación
class NotificationItemModel {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool read;
  final Timestamp timestamp;

  NotificationItemModel({
    required this.id,
    required this.icon,
    this.iconColor = Colors.grey,
    required this.title,
    this.read = false,
    required this.timestamp,
  });

  factory NotificationItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Uso de `??` para manejar posibles valores nulos de forma segura.
    final int iconCodePoint = data['iconCodePoint'] as int? ?? 0;
    final String iconFontFamily = data['iconFontFamily'] as String? ?? 'MaterialIcons';
    final int iconColorValue = data['iconColorValue'] as int? ?? Colors.grey.toARGB32();

    return NotificationItemModel(
      id: doc.id,
      icon: IconData(iconCodePoint, fontFamily: iconFontFamily),
      iconColor: Color(iconColorValue),
      title: data['title'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconColorValue': iconColor.toARGB32(),
      'title': title,
      'read': read,
      'timestamp': timestamp,
    };
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedIndex = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Configura el local de timeago a español
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  void _handleBottomNavigation(int index) {
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

  Future<void> _markNotificationAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Usuario no autenticado. No se puede marcar notificación como leída.');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
      logger.i('Notificación $notificationId marcada como leída.');
    } catch (e) {
      logger.e('Error al marcar notificación como leída: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error: Usuario no autenticado.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            logger.e('Error en el StreamBuilder: ${snapshot.error}');
            return Center(child: Text('Error al cargar notificaciones: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No tienes notificaciones.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs
              .map((doc) => NotificationItemModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
        onTap: (index) {
          logger.i('Navegación inferior en NotificationsScreen: $index');
          setState(() {
            _selectedIndex = index;
          });
          _handleBottomNavigation(index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItemModel notification) {
    // Formatea el timestamp a "hace 5 minutos" usando timeago
    final timeAgoString = timeago.format(notification.timestamp.toDate(), locale: 'es');

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: notification.read ? 0.5 : 2,
      color: notification.read ? Colors.grey[100] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: () {
          logger.i('Notificación "${notification.title}" presionada.');
          if (!notification.read) {
            _markNotificationAsRead(notification.id);
          }
        },
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: notification.iconColor.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(notification.icon, size: 28, color: notification.iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: notification.read ? Colors.grey[600] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgoString,
                      style: TextStyle(
                        fontSize: 14,
                        color: notification.read ? Colors.grey[500] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: notification.read ? Colors.grey[400] : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}