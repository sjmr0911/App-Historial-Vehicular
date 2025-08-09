// lib/screens/Perfil/help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening email and phone links
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';


var logger = Logger(printer: PrettyPrinter());

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _faqs = [];
  List<Map<String, String>> _filteredFaqs = [];
  bool _isLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
    _searchController.addListener(_filterFaqs);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFaqs);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFaqs() async {
    try {
      final querySnapshot = await _firestore.collection('faqs').get();
      setState(() {
        _faqs = querySnapshot.docs
            .map((doc) => {
                  'question': doc['question'] as String,
                  'answer': doc['answer'] as String,
                })
            .toList();
        _filteredFaqs = List.from(_faqs); // Inicialmente, todos los FAQs
        _isLoading = false;
      });
      logger.i('FAQs cargadas: ${_faqs.length}');
    } catch (e) {
      logger.e('Error al cargar FAQs: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar FAQs: $e')),
        );
      }
    }
  }

  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFaqs = _faqs.where((faq) {
        return faq['question']!.toLowerCase().contains(query) ||
               faq['answer']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    logger.i('Navegación inferior en HelpSupportScreen: ${_getBottomNavItemName(index)} (índice: $index)');
    _handleBottomNavigation(index); // Delegar la navegación real
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

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
      logger.i('Abriendo correo electrónico a: $email');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la aplicación de correo.')),
        );
      }
      logger.e('No se pudo abrir la aplicación de correo para: $email');
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
      logger.i('Realizando llamada a: $phoneNumber');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo realizar la llamada.')),
        );
      }
      logger.e('No se pudo realizar la llamada a: $phoneNumber');
    }
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
            logger.i('Volver desde Ayuda y Soporte');
            Navigator.pop(context); // Vuelve a ProfileScreen
          },
        ),
        title: const Text(
          'Ayuda y Soporte',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Barra de búsqueda de FAQ
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en Preguntas Frecuentes...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
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
            const SizedBox(height: 24),

            // Sección de Preguntas Frecuentes
            const Text(
              'Preguntas Frecuentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFaqs.isEmpty
                    ? const Text('No se encontraron preguntas frecuentes.', style: TextStyle(color: Colors.grey))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredFaqs.length,
                        itemBuilder: (context, index) {
                          final faq = _filteredFaqs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ExpansionTile(
                              title: Text(
                                faq['question']!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Text(
                                    faq['answer']!,
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            const SizedBox(height: 24),

            // Sección de Contacto
            const Text(
              'Contáctanos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email, color: Color(0xFF1E88E5)),
                    title: const Text('Envíanos un correo'),
                    subtitle: const Text('soporte@vehiculoapp.com'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () => _launchEmail('soporte@vehiculoapp.com'),
                  ),
                  const Divider(height: 0), // Thin divider between list tiles
                  ListTile(
                    leading: const Icon(Icons.phone, color: Color(0xFF1E88E5)),
                    title: const Text('Llámanos'),
                    subtitle: const Text('+1 809-555-1234'), // Example number
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () => _launchPhone('+18095551234'),
                  ),
                ],
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
        onTap: _onItemTapped, // This only updates the local index, navigation is handled by _handleBottomNavigation
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
