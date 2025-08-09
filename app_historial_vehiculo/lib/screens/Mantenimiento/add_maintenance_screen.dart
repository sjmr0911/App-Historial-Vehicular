import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_added_success_screen.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';
import 'package:app_historial_vehiculo/models/maintenance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

var logger = Logger(printer: PrettyPrinter());

class AddMaintenanceScreen extends StatefulWidget {
  const AddMaintenanceScreen({super.key});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _tipoMantenimiento;
  String? _selectedVehicleId;
  String? _selectedVehicleName;
  DateTime? _selectedDate;
  final TextEditingController _tallerResponsableController =
      TextEditingController();
  final TextEditingController _kilometrajeController = TextEditingController();
  final TextEditingController _costoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final String _estado = 'Pendiente';
  List<Map<String, String>> _vehicleOptions = [];
  bool _isSaving = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  @override
  void dispose() {
    _tallerResponsableController.dispose();
    _kilometrajeController.dispose();
    _costoController.dispose();
    _descripcionController.dispose();
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
        if (_vehicleOptions.isNotEmpty) {
          _selectedVehicleId = _vehicleOptions.first['id'];
          _selectedVehicleName = _vehicleOptions.first['name'];
        }
      });
    } catch (e) {
      logger.e('Error al cargar vehículos: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      logger.i('Fecha seleccionada: ${DateFormat('dd/MM/yyyy').format(picked)}');
    }
  }

  /// Crea una notificación en Firestore para el nuevo mantenimiento.
  Future<void> _createMaintenanceNotification(Maintenance maintenance) async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('Error: Usuario no autenticado al crear notificación de mantenimiento.');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title':
            'Nuevo registro de mantenimiento para ${maintenance.vehiculo}: ${maintenance.tipoMantenimiento}',
        'iconCodePoint': Icons.build_circle_outlined.codePoint,
        'iconFontFamily': 'MaterialIcons',
        'iconColorValue': Colors.blue.toARGB32(),
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      logger.i('Notificación de nuevo mantenimiento creada con éxito.');
    } catch (e) {
      logger.e('Error al crear notificación de nuevo mantenimiento: $e');
    }
  }

  void _onItemTapped(int index) {
    Widget screenToNavigate;
    switch (index) {
      case 0:
        screenToNavigate = const HomeScreen();
        break;
      case 1:
        screenToNavigate = const MyVehiclesListScreen();
        break;
      case 2:
        screenToNavigate = const MaintenanceListScreen();
        break;
      case 3:
        screenToNavigate = const ExpensesScreen();
        break;
      case 4:
        screenToNavigate = const ProfileScreen();
        break;
      default:
        return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screenToNavigate),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _saveMaintenance() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedVehicleId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Por favor, selecciona un vehículo.')),
          );
        }
        return;
      }
      if (_selectedDate == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, selecciona una fecha.')),
          );
        }
        return;
      }
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Usuario no autenticado.')),
          );
        }
        logger.e('Error: Usuario no autenticado al intentar guardar mantenimiento.');
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final newMaintenance = Maintenance(
          id: _firestore
              .collection('users')
              .doc(user.uid)
              .collection('maintenances')
              .doc()
              .id,
          tipoMantenimiento: _tipoMantenimiento!,
          vehiculo: _selectedVehicleName!,
          vehicleId: _selectedVehicleId!,
          fecha: _selectedDate!,
          tallerResponsable: _tallerResponsableController.text.trim().isEmpty
              ? null
              : _tallerResponsableController.text.trim(),
          kilometraje: int.tryParse(_kilometrajeController.text.trim()) ?? 0,
          costo: double.tryParse(_costoController.text.trim()) ?? 0.0,
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          estado: _estado,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('maintenances')
            .doc(newMaintenance.id)
            .set(newMaintenance.toFirestore());

        await _createMaintenanceNotification(newMaintenance);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const MaintenanceAddedSuccessScreen()),
            (Route<dynamic> route) => false,
          );
          logger.i('Mantenimiento "${newMaintenance.tipoMantenimiento}" agregado exitosamente.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar mantenimiento: $e')),
          );
        }
        logger.e('Error al guardar mantenimiento: $e');
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
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
          'Nuevo Registro de Mantenimiento',
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
                label: 'Tipo de Mantenimiento',
                value: _tipoMantenimiento,
                hintText: 'Ej. Cambio de aceite, Revisión general',
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, ingrese un tipo.' : null,
                onChanged: (value) {
                  setState(() {
                    _tipoMantenimiento = value;
                  });
                },
              ),
              _buildDropdownField(
                label: 'Vehículo',
                value: _selectedVehicleId,
                items: _vehicleOptions,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedVehicleId = newValue;
                    if (newValue != null) {
                      _selectedVehicleName = _vehicleOptions
                          .firstWhere((element) => element['id'] == newValue)['name'];
                    }
                  });
                },
              ),
              _buildDateField(),
              _buildTextFieldWithController(
                label: 'Taller o persona responsable',
                controller: _tallerResponsableController,
                hintText: 'Nombre del taller o persona',
              ),
              _buildTextFieldWithController(
                label: 'Kilometraje',
                controller: _kilometrajeController,
                hintText: 'Ej. 120000',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el kilometraje.';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor, ingrese un número válido.';
                  }
                  return null;
                },
              ),
              _buildTextFieldWithController(
                label: 'Costo',
                controller: _costoController,
                hintText: 'Ej. 75.50',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el costo.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, ingrese un número válido.';
                  }
                  return null;
                },
              ),
              _buildTextFieldWithController(
                label: 'Descripción',
                controller: _descripcionController,
                hintText: 'Detalles del mantenimiento realizado...',
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car), label: 'Vehículos'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Mantenimiento'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Gastos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: 2,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildTextFieldWithController({
    required String label,
    required TextEditingController controller,
    String hintText = '',
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2.0),
              ),
              prefixIcon: prefixIcon,
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? value,
    String hintText = '',
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2.0),
              ),
            ),
            validator: validator,
            onChanged: onChanged,
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
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2.0),
              ),
            ),
            items: items.map((Map<String, String> item) {
              return DropdownMenuItem<String>(
                value: item['id'],
                child: Text(item['name']!),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (value) =>
                value == null ? 'Por favor, seleccione un vehículo.' : null,
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
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: TextFormField(
                controller: TextEditingController(
                  text: _selectedDate != null
                      ? DateFormat('MM/dd/yyyy').format(_selectedDate!)
                      : '',
                ),
                decoration: InputDecoration(
                  hintText: 'mm/dd/yyyy',
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 20.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E88E5), width: 2.0),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                ),
                validator: (val) {
                  if (_selectedDate == null) {
                    return 'Por favor, seleccione la fecha';
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}