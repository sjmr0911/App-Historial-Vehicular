import 'package:app_historial_vehiculo/models/maintenance.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/changes_saved_success_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_completed_success_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

var logger = Logger(printer: PrettyPrinter());

class EditMaintenanceScreen extends StatefulWidget {
  final Maintenance maintenance;

  const EditMaintenanceScreen({super.key, required this.maintenance});

  @override
  State<EditMaintenanceScreen> createState() => _EditMaintenanceScreenState();
}

class _EditMaintenanceScreenState extends State<EditMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _typeController;
  late TextEditingController _dateController;
  late TextEditingController _mileageController;
  late TextEditingController _costController;
  late TextEditingController _descriptionController;
  late TextEditingController _responsibleController; // Controlador para el nuevo campo "Taller"

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedIndex = 2;

  String? _selectedVehicleId;
  String? _selectedVehicleName;
  late String _currentStatus;
  List<Map<String, String>> _vehicleOptions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.maintenance.tipoMantenimiento);
    _dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(widget.maintenance.fecha));
    _mileageController = TextEditingController(text: widget.maintenance.kilometraje.toString());
    _costController = TextEditingController(text: widget.maintenance.costo.toStringAsFixed(2));
    _descriptionController = TextEditingController(text: widget.maintenance.descripcion);
    _responsibleController = TextEditingController(text: widget.maintenance.tallerResponsable); // Inicializar el nuevo controlador

    _selectedVehicleId = widget.maintenance.vehicleId;
    _selectedVehicleName = widget.maintenance.vehiculo;
    _currentStatus = widget.maintenance.estado;

    _fetchVehicles();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _dateController.dispose();
    _mileageController.dispose();
    _costController.dispose();
    _descriptionController.dispose();
    _responsibleController.dispose(); // Desechar el nuevo controlador
    super.dispose();
  }

  Future<void> _fetchVehicles() async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Usuario no autenticado.');
      return;
    }

    try {
      final vehiclesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .get();

      final options = vehiclesSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': '${doc.data()['brandModel']} (${doc.data()['plate']})',
        };
      }).toList();

      setState(() {
        _vehicleOptions = options;
        
        // CORRECCIÓN: Actualizar el valor del vehículo seleccionado
        if (_selectedVehicleId != null) {
          final currentVehicle = _vehicleOptions.firstWhere(
            (element) => element['id'] == _selectedVehicleId,
            orElse: () => {'id': '', 'name': ''}
          );
          if (currentVehicle['id'] != '') {
              _selectedVehicleName = currentVehicle['name'];
          } else {
              _selectedVehicleName = null;
              _selectedVehicleId = null;
          }
        }
      });
    } catch (e) {
      logger.e('Error al cargar vehículos: $e');
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

  Future<void> _saveMaintenance() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleId == null || _selectedVehicleName == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, seleccione un vehículo válido.')),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      logger.e('Usuario no autenticado.');
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(_dateController.text);

      final updatedMaintenance = Maintenance(
        id: widget.maintenance.id,
        tipoMantenimiento: _typeController.text,
        vehiculo: _selectedVehicleName!,
        vehicleId: _selectedVehicleId!,
        fecha: parsedDate,
        kilometraje: int.parse(_mileageController.text),
        costo: double.parse(_costController.text),
        estado: _currentStatus,
        tallerResponsable: _responsibleController.text, // Guardar el valor del nuevo campo
        descripcion: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('maintenances')
          .doc(updatedMaintenance.id)
          .update(updatedMaintenance.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mantenimiento actualizado exitosamente.')),
        );

        if (updatedMaintenance.estado == 'Completado') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MaintenanceCompletedSuccessScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ChangesSavedSuccessScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      logger.e('Error al actualizar el mantenimiento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.maintenance.fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Mantenimiento',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveMaintenance,
            child: Text(
              'Guardar',
              style: TextStyle(
                color: _isSaving ? Colors.grey : const Color(0xFF1E88E5),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _typeController,
                label: 'Tipo de Mantenimiento',
                validator: (value) => value!.isEmpty ? 'Por favor, ingrese un tipo.' : null,
              ),
              _buildDropdownField(
                label: 'Vehículo',
                value: _selectedVehicleId,
                items: _vehicleOptions,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedVehicleId = newValue;
                    _selectedVehicleName = _vehicleOptions.firstWhere((element) => element['id'] == newValue)['name'];
                  });
                },
              ),
              _buildDateField(),
              _buildTextField(
                controller: _responsibleController,
                label: 'Taller o persona responsable',
                validator: (value) => null,
              ),
              _buildTextField(
                controller: _mileageController,
                label: 'Kilometraje',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Por favor, ingrese el kilometraje.';
                  if (int.tryParse(value) == null) return 'Por favor, ingrese un número válido.';
                  return null;
                },
              ),
              _buildTextField(
                controller: _costController,
                label: 'Costo',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Por favor, ingrese el costo.';
                  if (double.tryParse(value) == null) return 'Por favor, ingrese un número válido.';
                  return null;
                },
              ),
              _buildTextField(
                controller: _descriptionController,
                label: 'Descripción',
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                validator: (value) => null,
              ),
              _buildStatusTabs(),
              const SizedBox(height: 20),
            ],
          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
              ),
            ),
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
              ),
            ),
            items: items.map((Map<String, String> item) {
              return DropdownMenuItem<String>(
                value: item['id'],
                child: Text(item['name']!),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (value) => value == null ? 'Por favor, seleccione un vehículo.' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fecha',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _dateController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
              ),
              suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
            ),
            readOnly: true,
            onTap: () => _selectDate(context),
            validator: (value) => value!.isEmpty ? 'Por favor, ingrese una fecha.' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado del Mantenimiento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentStatus = 'Pendiente';
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _currentStatus == 'Pendiente' ? const Color(0xFF1E88E5) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Pendiente',
                      style: TextStyle(
                        color: _currentStatus == 'Pendiente' ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentStatus = 'Completado';
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _currentStatus == 'Completado' ? const Color(0xFF1E88E5) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Completado',
                      style: TextStyle(
                        color: _currentStatus == 'Completado' ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}