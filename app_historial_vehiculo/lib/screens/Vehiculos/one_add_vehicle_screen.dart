// lib/screens/Vehiculos/one_add_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/no_vehicles_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/vehicle_added_success_screen.dart';
import 'package:app_historial_vehiculo/models/vehicle.dart' as vehicle_model;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

var logger = Logger(printer: PrettyPrinter());

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
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

  // --- FUNCIÓN PARA VERIFICAR Y AGREGAR NOTIFICACIÓN DEL PRIMER VEHÍCULO ---
  Future<void> _checkAndAddFirstVehicleNotification() async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Error: Usuario no autenticado para agregar notificación.');
      return;
    }

    try {
      final vehiclesQuery = await _firestore.collection('users').doc(user.uid).collection('vehicles').get();
      if (vehiclesQuery.docs.isEmpty) {
        // Es el primer vehículo del usuario, se agrega la notificación especial
        await _firestore.collection('users').doc(user.uid).collection('notifications').add({
          'iconCodePoint': Icons.star.codePoint,
          'iconFontFamily': 'MaterialIcons',
          'iconColorValue': Colors.yellow.toARGB32(),
          'title': 'Se agregó tu primer vehículo. ¡Felicidades!',
          'read': false,
          'timestamp': Timestamp.now(),
        });
        logger.i('Notificación de primer vehículo agregada.');
      }
    } catch (e) {
      logger.e('Error al verificar y agregar notificación de primer vehículo: $e');
    }
  }

  Future<void> _saveVehicle() async {
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

      // --- LLAMADA A LA NUEVA FUNCIÓN DE NOTIFICACIÓN ---
      await _checkAndAddFirstVehicleNotification();

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

  Widget _buildTextField(String label, String hint, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
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
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 50),
            const Text(
              'Añade tu primer vehículo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Empieza a gestionar tu vehiculo.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 30),
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
            const SizedBox(height: 24),
            _buildTextField('Marca', 'Ej: Toyota', _brandController),
            const SizedBox(height: 16),
            _buildTextField('Modelo', 'Ej: Corolla', _modelController),
            const SizedBox(height: 16),
            _buildTextField('Año', 'Ej: 2020', _yearController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField('Color', 'Ej: Rojo', _colorController),
            const SizedBox(height: 16),
            _buildTextField('Placa', 'Ej: ABC-1234', _plateController),
            const SizedBox(height: 16),
            _buildTextField('Kilometraje actual', 'Ej: 50000', _mileageController, keyboardType: TextInputType.number),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Guardar vehículo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () {
                  logger.i('Se hizo clic en "Saltar por ahora"');
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const NoVehiclesScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Saltar por ahora',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
