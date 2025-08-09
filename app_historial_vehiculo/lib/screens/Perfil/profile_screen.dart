// lib/screens/Perfil/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Nueva importación
import 'package:cloud_firestore/cloud_firestore.dart'; // Nueva importación

import 'package:app_historial_vehiculo/screens/Perfil/personal_info_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/notification_settings_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/documents_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/security_privacy_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/help_support_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/logout_confirmation_screen.dart';

// Importaciones de pantallas principales para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';


var logger = Logger(printer: PrettyPrinter());

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Variables para almacenar la información del usuario
  String _fullName = 'Cargando...';
  String _email = 'Cargando...';
  String _profileImageUrl = 'https://placehold.co/100x100/png';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Método para cargar la información del usuario desde Firestore
  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Usuario no autenticado. No se cargará el perfil.');
      return;
    }

    // Escuchar cambios en el documento del usuario en tiempo real
    _firestore.collection('users').doc(user.uid).snapshots().listen((docSnapshot) {
      if (docSnapshot.exists && mounted) {
        final data = docSnapshot.data();
        if (data != null) {
          final name = data['name'] ?? '';
          final lastName = data['lastName'] ?? '';
          final email = data['email'] ?? user.email ?? '';
          final profileImageUrl = data['profileImageUrl'] ?? 'https://placehold.co/100x100/png';

          setState(() {
            _fullName = '$name $lastName'.trim();
            _email = email;
            _profileImageUrl = profileImageUrl;
          });
          logger.i('Información del perfil actualizada en tiempo real.');
        }
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      logger.i('Imagen seleccionada: ${pickedFile.path}');
    } else {
      logger.i('Selección de imagen cancelada.');
    }
  }

  void _handleBottomNavigation(BuildContext context, int index) {
    Widget screenToNavigate;
    switch (index) {
      case 0: screenToNavigate = const HomeScreen(); break;
      case 1: screenToNavigate = const MyVehiclesListScreen(); break;
      case 2: screenToNavigate = const MaintenanceListScreen(); break;
      case 3: screenToNavigate = const ExpensesScreen(); break;
      case 4: return;
      default: return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screenToNavigate),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color iconColor = Colors.black87,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isLogout ? Colors.red : Colors.black87,
                  fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (!isLogout)
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
            onPressed: () {
              logger.i('Navegando a Información Personal');
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Sección de Perfil de Usuario
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider
                        : NetworkImage(_profileImageUrl) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E88E5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _fullName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                _email,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 32),
            
            // Sección "Cuenta"
            const Text(
              'Cuenta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildOptionTile(
                    icon: Icons.person_outline,
                    title: 'Información Personal',
                    onTap: () {
                      logger.i('Navegando a Información Personal');
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen()));
                    },
                  ),
                  const Divider(height: 0),
                  _buildOptionTile(
                    icon: Icons.notifications_none,
                    title: 'Notificaciones',
                    onTap: () {
                      logger.i('Navegando a Notificaciones');
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sección "Vehículos"
            const Text(
              'Vehículos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildOptionTile(
                icon: Icons.folder_open_outlined,
                title: 'Documentos',
                onTap: () {
                  logger.i('Navegando a Documentos');
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DocumentsScreen()));
                },
              ),
            ),
            const SizedBox(height: 24),

            // Sección "General"
            const Text(
              'General',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildOptionTile(
                    icon: Icons.security,
                    title: 'Seguridad y Privacidad',
                    onTap: () {
                      logger.i('Navegando a Seguridad y Privacidad');
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityPrivacyScreen()));
                    },
                  ),
                  const Divider(height: 0),
                  _buildOptionTile(
                    icon: Icons.help_outline,
                    title: 'Ayuda y Soporte',
                    onTap: () {
                      logger.i('Navegando a Ayuda y Soporte');
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón de Cerrar Sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  logger.i('Navegando a Confirmación de Cerrar Sesión');
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LogoutConfirmationScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Cerrar Sesión',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Vehículos'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Mantenimiento'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Gastos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: 4,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          logger.i('Navegación inferior en ProfileScreen: $index');
          _handleBottomNavigation(context, index);
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}