// lib/screens/Perfil/personal_info_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';


var logger = Logger(printer: PrettyPrinter());

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  int _selectedIndex = 4;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadPersonalInfo();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalInfo() async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Usuario no autenticado. No se cargará la información personal.');
      return;
    }

    try {
      // Leer directamente desde el documento del usuario en la colección 'users'
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          final name = data['name'] ?? '';
          final lastName = data['lastName'] ?? '';
          final fullName = '$name $lastName'.trim();

          setState(() {
            _fullNameController.text = fullName;
            _emailController.text = data['email'] ?? user.email ?? '';
            _phoneController.text = data['phone'] ?? ''; // Leer el nuevo campo 'phone'
          });
          logger.i('Información personal cargada desde el documento del usuario.');
        }
      } else {
        // Si no hay datos, usar los de Firebase Auth y por defecto
        setState(() {
          _fullNameController.text = 'Usuario Nuevo';
          _emailController.text = user.email ?? 'correo@ejemplo.com';
          _phoneController.text = '';
        });
        logger.i('No se encontró información personal existente. Usando datos de Auth y por defecto.');
      }
    } catch (e) {
      logger.e('Error al cargar información personal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar información: $e')),
        );
      }
    }
  }

  Future<void> _savePersonalInfo() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardando información personal...')),
      );
    }

    try {
      // Dividir el nombre completo en nombre y apellido
      final fullName = _fullNameController.text.trim();
      List<String> names = fullName.split(' ');
      String name = names.isNotEmpty ? names.first : '';
      String lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
      
      // Actualizar el documento principal del usuario
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'lastName': lastName,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // También actualizar el email en Firebase Auth si ha cambiado
      if (user.email != _emailController.text.trim()) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
        logger.i('Email de Firebase Auth actualizado.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Información personal guardada con éxito.')),
        );
        Navigator.pop(context);
      }
      logger.i('Información personal guardada.');
    } on FirebaseAuthException catch (e) {
      // ... (código de manejo de errores de autenticación)
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        String errorMessage;
        if (e.code == 'requires-recent-login') {
          errorMessage = 'Por favor, inicie sesión de nuevo para actualizar su email.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'El formato del correo electrónico es inválido.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'El correo electrónico ya está en uso por otra cuenta.';
        } else {
          errorMessage = 'Error al actualizar email: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      logger.e('Error de Firebase al guardar información personal: ${e.code} - ${e.message}');
    } catch (e) {
      // ... (código de manejo de errores genérico)
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado al guardar información personal: $e')),
        );
      }
      logger.e('Error inesperado al guardar información personal: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    logger.i('Navegación inferior en PersonalInfoScreen: ${_getBottomNavItemName(index)} (índice: $index)');
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () {
            logger.i('Volver desde Información Personal');
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Información Personal',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildLabeledTextField('Nombre Completo', _fullNameController),
            const SizedBox(height: 20),
            _buildLabeledTextField('Correo Electrónico', _emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildLabeledTextField('Número de Teléfono', _phoneController, keyboardType: TextInputType.phone),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _savePersonalInfo,
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

  Widget _buildLabeledTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}