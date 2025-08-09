// lib/screens/Vehiculos/add_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Required for File
import 'package:app_historial_vehiculo/models/vehicle.dart' as vehicle_model;
import 'package:app_historial_vehiculo/screens/Vehiculos/vehicle_added_success_screen.dart';
import 'package:logger/logger.dart'; // Import logger
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage

var logger = Logger(printer: PrettyPrinter());

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  File? _selectedImage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      logger.i('Imagen seleccionada: ${pickedFile.path}');
    } else {
      logger.i('Selección de imagen cancelada.');
    }
  }

  // --- NUEVA FUNCIÓN: AGREGAR NOTIFICACIÓN ---
  Future<void> _addNotification(String title) async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Error: Usuario no autenticado para agregar notificación.');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).collection('notifications').add({
        'iconCodePoint': Icons.directions_car.codePoint,
        'iconFontFamily': 'MaterialIcons',
        'iconColorValue': Colors.blue.toARGB32(),
        'title': title,
        'read': false,
        'timestamp': Timestamp.now(),
      });
      logger.i('Notificación agregada: $title');
    } catch (e) {
      logger.e('Error al agregar notificación: $e');
    }
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Usuario no autenticado.')),
          );
        }
        logger.e('Error: Usuario no autenticado al intentar guardar vehículo.');
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardando vehículo...')),
        );
      }

      try {
        String imageUrl = '';
        if (_selectedImage != null) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.path.split('/').last}';
          final ref = _storage.ref().child('vehicle_images').child('${user.uid}/$fileName');
          await ref.putFile(_selectedImage!);
          imageUrl = await ref.getDownloadURL();
          logger.i('Imagen subida a Storage: $imageUrl');
        }

        final vehicleDocRef = _firestore.collection('users').doc(user.uid).collection('vehicles').doc();
        final vehicleId = vehicleDocRef.id;

        final int? year = int.tryParse(_yearController.text.trim());
        final int? mileage = int.tryParse(_mileageController.text.trim());

        if (year == null || mileage == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: El año y el kilometraje deben ser números válidos.')),
            );
          }
          return;
        }

        final newVehicle = vehicle_model.Vehicle(
          id: vehicleId,
          name: _brandController.text.trim(),
          brandModel: _modelController.text.trim(),
          year: year,
          color: _colorController.text.trim(),
          plate: _plateController.text.trim(),
          mileage: mileage,
          imageUrl: imageUrl,
        );

        await vehicleDocRef.set(newVehicle.toFirestore());

        // --- LLAMADA A LA FUNCIÓN DE NOTIFICACIÓN ---
        final notificationTitle = 'Vehículo "${newVehicle.brandModel}" agregado exitosamente.';
        await _addNotification(notificationTitle);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const VehicleAddedSuccessScreen()),
            (Route<dynamic> route) => false,
          );
          logger.i('Vehículo "${newVehicle.name} ${newVehicle.brandModel}" agregado exitosamente.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al agregar vehículo: $e')),
          );
        }
        logger.e('Error al agregar vehículo: $e');
      }
    }
  }

  Widget _buildValidatedTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa $label';
            }
            if (keyboardType == TextInputType.number && int.tryParse(value) == null) {
              return 'Por favor ingresa un valor numérico válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Vehículo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : null,
                    child: _selectedImage == null
                        ? Icon(
                            Icons.camera_alt,
                            color: Colors.grey[700],
                            size: 40,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Añadir foto del vehículo',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 24),
              _buildValidatedTextField(
                label: 'Marca',
                hintText: 'Ej: Ford',
                controller: _brandController,
              ),
              const SizedBox(height: 16),
              _buildValidatedTextField(
                label: 'Modelo',
                hintText: 'Ej: Focus',
                controller: _modelController,
              ),
              const SizedBox(height: 16),
              _buildValidatedTextField(
                label: 'Año',
                hintText: 'Ej: 2020',
                controller: _yearController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildValidatedTextField(
                label: 'Color',
                hintText: 'Ej: Rojo',
                controller: _colorController,
              ),
              const SizedBox(height: 16),
              _buildValidatedTextField(
                label: 'Placa',
                hintText: 'Ej: 1234 ABC',
                controller: _plateController,
              ),
              const SizedBox(height: 16),
              _buildValidatedTextField(
                label: 'Kilometraje actual',
                hintText: 'Ej: 50000',
                controller: _mileageController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _saveVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Guardar vehículo',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}