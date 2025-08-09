// lib/screens/Vehiculos/edit_vehicle_screen.dart

import 'package:flutter/material.dart';
import 'package:app_historial_vehiculo/models/vehicle.dart' as vehicle_model;
import 'package:app_historial_vehiculo/screens/Vehiculos/changes_saved_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:logger/logger.dart';

var logger = Logger(printer: PrettyPrinter());

class EditVehicleScreen extends StatefulWidget {
  final vehicle_model.Vehicle vehicle;

  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _colorController; // Nuevo: Controlador para el color
  late TextEditingController _plateController;
  late TextEditingController _mileageController;
  File? _selectedImage;
  late String _imageUrl;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.vehicle.name);
    _modelController = TextEditingController(text: widget.vehicle.brandModel);
    _yearController = TextEditingController(text: widget.vehicle.year.toString());
    _colorController = TextEditingController(text: widget.vehicle.color); // Nuevo: Inicializar con el valor del vehículo
    _plateController = TextEditingController(text: widget.vehicle.plate);
    _mileageController = TextEditingController(text: widget.vehicle.mileage.toString());
    _imageUrl = widget.vehicle.imageUrl;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose(); // Nuevo: Liberar el controlador de color
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
      logger.i('Nueva imagen seleccionada: ${pickedFile.path}');
    } else {
      logger.i('Selección de imagen cancelada.');
    }
  }

  Future<void> _saveChanges() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      logger.e('Error: Usuario no autenticado al intentar guardar cambios.');
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardando cambios...')),
      );
    }

    try {
      String newImageUrl = _imageUrl;
      if (_selectedImage != null) {
        final ref = _storage.ref().child('vehicle_images').child('${user.uid}/${widget.vehicle.id}.jpg');
        await ref.putFile(_selectedImage!);
        newImageUrl = await ref.getDownloadURL();
        logger.i('Imagen subida a Storage: $newImageUrl');
      }

      final int? year = int.tryParse(_yearController.text.trim());
      final int? mileage = int.tryParse(_mileageController.text.trim());

      if (year == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: El año debe ser un número válido.')),
          );
        }
        return;
      }

      if (mileage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: El kilometraje debe ser un número válido.')),
          );
        }
        return;
      }

      final updatedData = {
        'name': _brandController.text.trim(),
        'brandModel': _modelController.text.trim(),
        'year': year,
        'color': _colorController.text.trim(), // Nuevo: Se agrega el color
        'plate': _plateController.text.trim(),
        'mileage': mileage,
        'imageUrl': newImageUrl,
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .update(updatedData);

      final updatedVehicle = vehicle_model.Vehicle(
        id: widget.vehicle.id,
        name: _brandController.text.trim(),
        brandModel: _modelController.text.trim(),
        year: year,
        color: _colorController.text.trim(), // Nuevo: Se pasa el valor del color
        plate: _plateController.text.trim(),
        mileage: mileage,
        imageUrl: newImageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ChangesSavedScreen(expense: updatedData)),
          (Route<dynamic> route) => false,
        );
        logger.i('Vehículo "${updatedVehicle.name} ${updatedVehicle.brandModel}" actualizado exitosamente.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar cambios: $e')),
        );
      }
      logger.e('Error al guardar cambios del vehículo: $e');
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Vehículo'),
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
                      : (_imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null) as ImageProvider?,
                  child: _selectedImage == null && _imageUrl.isEmpty
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
            _buildTextField('Marca', _brandController),
            const SizedBox(height: 16),
            _buildTextField('Modelo', _modelController),
            const SizedBox(height: 16),
            _buildTextField('Año', _yearController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField('Color', _colorController), // Nuevo: Campo de texto para el color
            const SizedBox(height: 16),
            _buildTextField('Placa', _plateController),
            const SizedBox(height: 16),
            _buildTextField('Kilometraje actual', _mileageController, keyboardType: TextInputType.number),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    );
  }
}