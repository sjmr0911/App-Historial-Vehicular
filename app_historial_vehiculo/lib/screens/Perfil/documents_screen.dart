// lib/screens/Perfil/documents_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // Para el BottomNavigationBar
import 'dart:async'; // For StreamSubscription


var logger = Logger(printer: PrettyPrinter());

// Modelo simple para un documento
class DocumentItem {
  final String id;
  final String title;
  final String subtitle; // e.g., "PDF - 2.5 MB"
  final String fileUrl; // URL de descarga del documento

  DocumentItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.fileUrl,
  });

  factory DocumentItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return DocumentItem(
      id: doc.id,
      title: data['title'] ?? 'Documento sin título',
      subtitle: data['subtitle'] ?? 'Tipo desconocido',
      fileUrl: data['fileUrl'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'fileUrl': fileUrl,
      'timestamp': FieldValue.serverTimestamp(), // Para ordenar por fecha de subida
    };
  }
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  int _selectedIndex = 4; // Asumo que se llega aquí desde Perfil
  List<DocumentItem> _documents = [];
  bool _isLoading = true;
  StreamSubscription? _documentsSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  @override
  void dispose() {
    _documentsSubscription?.cancel();
    super.dispose();
  }

  void _fetchDocuments() {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Usuario no autenticado en DocumentsScreen. No se cargarán documentos.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _documentsSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('documents')
        .orderBy('timestamp', descending: true) // Ordenar por fecha de subida
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _documents = snapshot.docs.map((doc) => DocumentItem.fromFirestore(doc)).toList();
        _isLoading = false;
      });
      logger.i('Documentos cargados: ${_documents.length}');
    }, onError: (error) {
      logger.e('Error al cargar documentos: $error');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar documentos: $error')),
        );
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    logger.i('Navegación inferior en DocumentsScreen: ${_getBottomNavItemName(index)} (índice: $index)');
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

  Future<void> _addDocument() async {
    // Implementar la lógica para añadir un documento (e.g., ImagePicker, FilePicker)
    // Por ahora, un placeholder
    logger.i('Añadir nuevo documento presionado.');
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      return;
    }

    // Ejemplo de cómo añadir un documento dummy
    try {
      final newDocRef = _firestore.collection('users').doc(user.uid).collection('documents').doc();
      await newDocRef.set(DocumentItem(
        id: newDocRef.id,
        title: 'Documento de Prueba ${DateTime.now().second}',
        subtitle: 'PDF - 1.2 MB',
        fileUrl: 'https://www.example.com/dummy.pdf', // Placeholder URL
      ).toFirestore());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento de prueba añadido.')),
        );
      }
    } catch (e) {
      logger.e('Error al añadir documento de prueba: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir documento: $e')),
        );
      }
    }
  }

  Future<void> _deleteDocument(String docId) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      return;
    }

    // Confirmación antes de eliminar
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar este documento?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('documents')
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento eliminado con éxito.')),
          );
        }
        logger.i('Documento con ID $docId eliminado.');
      } catch (e) {
        logger.e('Error al eliminar documento: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar documento: $e')),
          );
        }
      }
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
            logger.i('Volver desde Documentos');
            Navigator.pop(context); // Vuelve a ProfileScreen
          },
        ),
        title: const Text(
          'Mis Documentos',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1E88E5), size: 30),
            onPressed: _addDocument,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          color: Colors.grey,
                          size: 100,
                        ),
                        SizedBox(height: 30),
                        Text(
                          '¡Aún no tienes documentos!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Sube documentos importantes de tu vehículo aquí para tenerlos siempre a mano.',
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return _buildDocumentCard(
                      title: doc.title,
                      subtitle: doc.subtitle,
                      onView: () {
                        logger.i('Ver documento: ${doc.title}');
                        if (doc.fileUrl.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Abriendo documento: ${doc.fileUrl}')),
                          );
                          // Aquí se usaría url_launcher para abrir la URL
                          // launchUrl(Uri.parse(doc.fileUrl));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No hay URL para ver este documento.')),
                          );
                        }
                      },
                      onDownload: () {
                        logger.i('Descargar documento: ${doc.title}');
                        if (doc.fileUrl.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Descargando documento: ${doc.fileUrl}')),
                          );
                          // Aquí se usaría url_launcher para descargar la URL
                          // launchUrl(Uri.parse(doc.fileUrl));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No hay URL para descargar este documento.')),
                          );
                        }
                      },
                      onDelete: () => _deleteDocument(doc.id),
                    );
                  },
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

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required VoidCallback onView,
    required VoidCallback onDownload,
    required VoidCallback onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Color(0xFF1E88E5), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDocumentAction(Icons.remove_red_eye_outlined, 'Ver', onView),
                _buildDocumentAction(Icons.download_outlined, 'Descargar', onDownload),
                _buildDocumentAction(Icons.delete_outline, 'Eliminar', onDelete, color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentAction(IconData icon, String text, VoidCallback onTap, {Color color = const Color(0xFF1E88E5)}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
