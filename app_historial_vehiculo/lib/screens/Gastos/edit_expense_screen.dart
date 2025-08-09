import 'package:flutter/material.dart';
import 'package:app_historial_vehiculo/screens/Gastos/changes_saved_screen.dart'; // Importa la pantalla de cambios guardados
import 'package:intl/intl.dart'; // Para formatear la fecha
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:app_historial_vehiculo/models/vehicle.dart'; // Importar el modelo Vehicle
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Para BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // Para BottomNavigationBar
import 'package:logger/logger.dart'; // Import logger
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // <-- CORRECCIÓN: Se agrega la importación para la clase 'ExpensesScreen'

var logger = Logger(printer: PrettyPrinter());

class EditExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedExpenseType;
  late String _selectedVehicleId;
  late String _selectedVehicleName;
  late DateTime _selectedDate;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedPaymentMethod;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> expenseTypes = [
    'Combustible',
    'Mantenimiento',
    'Reparación',
    'Peaje',
    'Lavado de coche',
    'Estacionamiento',
    'Seguro',
    'Impuestos',
    'Multa',
    'Otros'
  ];
  final List<String> paymentMethods = ['Efectivo', 'Transferencia', 'Tarjeta de Crédito'];

  @override
  void initState() {
    super.initState();
    _selectedExpenseType = widget.expense['tipo'] ?? expenseTypes[0];
    _selectedVehicleId = widget.expense['vehiculoId'] ?? ''; // Initialize with vehicle ID
    _selectedVehicleName = widget.expense['vehiculo'] ?? ''; // Initialize with vehicle name
    _selectedDate = DateFormat('dd/MM/yyyy').parse(widget.expense['fecha'] ?? DateFormat('dd/MM/yyyy').format(DateTime.now()));
    _amountController = TextEditingController(text: widget.expense['monto']?.toStringAsFixed(2) ?? '0.00');
    _descriptionController = TextEditingController(text: widget.expense['descripcion'] ?? '');
    _selectedPaymentMethod = widget.expense['metodoPago'] ?? paymentMethods[0];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
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

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Usuario no autenticado.')),
          );
        }
        logger.e('Error: Usuario no autenticado al intentar guardar cambios de gasto.');
        return;
      }

      // Muestra un indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardando cambios...')),
        );
      }

      try {
        final updatedExpense = {
          'id': widget.expense['id'],
          'tipo': _selectedExpenseType,
          'vehiculoId': _selectedVehicleId,
          'vehiculo': _selectedVehicleName,
          'fecha': DateFormat('dd/MM/yyyy').format(_selectedDate),
          'monto': double.parse(_amountController.text.trim()),
          'descripcion': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          'metodoPago': _selectedPaymentMethod,
        };

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .doc(updatedExpense['id'] as String)
            .update(updatedExpense);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ChangesSavedScreen(expense: updatedExpense)),
            (Route<dynamic> route) => false,
          );
          logger.i('Gasto "${updatedExpense['tipo']}" actualizado exitosamente.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar cambios de gasto: $e')),
          );
        }
        logger.e('Error al guardar cambios de gasto: $e');
      }
    }
  }

  // Método para manejar la navegación inferior
  void _handleBottomNavigation(int index) {
    Widget screenToNavigate;
    switch (index) {
      case 0: screenToNavigate = const HomeScreen(); break;
      case 1: screenToNavigate = const MyVehiclesListScreen(); break;
      case 2: screenToNavigate = const MaintenanceListScreen(); break;
      case 3: screenToNavigate = const ExpensesScreen(); break; // Ya estamos en Gastos
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
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Gasto'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdownField(
                'Tipo de Gasto',
                _selectedExpenseType,
                expenseTypes,
                (newValue) {
                  setState(() {
                    _selectedExpenseType = newValue!;
                  });
                },
                'Selecciona el tipo de gasto',
              ),
              const SizedBox(height: 16),
              Text(
                'Vehículo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300, width: 1.0),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: user != null
                      ? _firestore.collection('users').doc(user.uid).collection('vehicles').snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No hay vehículos disponibles.'));
                    }

                    List<Vehicle> vehicles = snapshot.data!.docs
                        .map((doc) => Vehicle.fromFirestore(doc))
                        .toList();

                    // Asegurarse de que el _selectedVehicleId sea válido si el vehículo original fue eliminado
                    if (!vehicles.any((v) => v.id == _selectedVehicleId)) {
                      _selectedVehicleId = vehicles.isNotEmpty ? vehicles.first.id : '';
                      _selectedVehicleName = vehicles.isNotEmpty ? vehicles.first.name : '';
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedVehicleId.isEmpty ? null : _selectedVehicleId,
                      hint: const Text('Selecciona un vehículo'),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      items: vehicles.map((vehicle) {
                        return DropdownMenuItem<String>(
                          value: vehicle.id,
                          child: Text('${vehicle.name} ${vehicle.brandModel}'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedVehicleId = newValue!;
                          _selectedVehicleName = vehicles.firstWhere((v) => v.id == newValue).name;
                        });
                        logger.i('Vehículo seleccionado: $_selectedVehicleName (ID: $_selectedVehicleId)');
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecciona un vehículo';
                        }
                        return null;
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildDateField(
                'Fecha',
                DateFormat('dd/MM/yyyy').format(_selectedDate),
                () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Monto',
                _amountController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.attach_money),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDescriptionField(
                'Descripción (Opcional)',
                _descriptionController,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                'Método de Pago',
                _selectedPaymentMethod,
                paymentMethods,
                (newValue) {
                  setState(() {
                    _selectedPaymentMethod = newValue!;
                  });
                },
                'Selecciona el método de pago',
              ),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Vehículos'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Mantenimiento'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Gastos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: 3, // Gastos
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          logger.i('Navegación inferior en EditExpenseScreen: $index');
          _handleBottomNavigation(index);
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, ValueChanged<String?> onChanged, String hintText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300, width: 1.0),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            hint: Text(hintText),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Por favor, selecciona una opción';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              controller: TextEditingController(text: value),
              decoration: InputDecoration(
                hintText: 'Selecciona la fecha',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: const Icon(Icons.calendar_today),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Por favor, selecciona la fecha';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        Widget? prefixIcon,
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: prefixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDescriptionField(
      String label,
      TextEditingController controller,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

