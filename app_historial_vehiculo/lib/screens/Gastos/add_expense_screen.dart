import 'package:flutter/material.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expense_added_screen.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_historial_vehiculo/models/vehicle.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedExpenseType;
  String? _selectedVehicleId;
  String? _selectedVehicleName;
  DateTime? _selectedDate;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedPaymentMethod;

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
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  // 🔄 MODIFICADO: Método para crear una notificación en Firestore con detalles y el color del ícono
  Future<void> _createSavedNotification(String expenseType, String vehicleName) async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.e('No se pudo crear la notificación: Usuario no autenticado.');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': 'Se ha creado un nuevo gasto',
        'subtitle': 'El gasto "$expenseType" para el vehículo "$vehicleName" ha sido registrado.',
        'iconCodePoint': Icons.calendar_today.codePoint, // 🔄 ACTUALIZADO: Guardar el codePoint del ícono
        'iconColorValue': Colors.green.toARGB32(), // 🔄 AGREGADO: Guardar el color del ícono
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      logger.i('Notificación de gasto "$expenseType" para $vehicleName creada exitosamente.');
    } catch (e) {
      logger.e('Error al crear la notificación de gasto: $e');
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedVehicleId == null || _selectedDate == null || _selectedExpenseType == null || _selectedPaymentMethod == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, completa todos los campos requeridos.')),
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
        logger.e('Error: Usuario no autenticado al intentar guardar gasto.');
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardando gasto...')),
        );
      }

      try {
        final newExpense = {
          'id': _firestore.collection('users').doc(user.uid).collection('expenses').doc().id,
          'tipo': _selectedExpenseType!,
          'vehiculoId': _selectedVehicleId!,
          'vehiculo': _selectedVehicleName!,
          'fecha': DateFormat('dd/MM/yyyy').format(_selectedDate!),
          'monto': double.parse(_amountController.text.trim()),
          'descripcion': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          'metodoPago': _selectedPaymentMethod!,
        };

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .doc(newExpense['id'] as String)
            .set(newExpense);

        await _createSavedNotification(_selectedExpenseType!, _selectedVehicleName!);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ExpenseAddedScreen(expense: newExpense)),
            (Route<dynamic> route) => false,
          );
          logger.i('Gasto "${newExpense['tipo']}" agregado exitosamente.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar gasto: $e')),
          );
        }
        logger.e('Error al guardar gasto: $e');
      }
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
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Gasto'),
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
                    _selectedExpenseType = newValue;
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

                    return DropdownButtonFormField<String>(
                      value: _selectedVehicleId,
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
                          _selectedVehicleId = newValue;
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
                _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : '',
                () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Monto',
                _amountController,
                hintText: 'Ej: 50.00',
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
                'Detalles del gasto...',
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                'Método de Pago',
                _selectedPaymentMethod,
                paymentMethods,
                (newValue) {
                  setState(() {
                    _selectedPaymentMethod = newValue;
                  });
                },
                'Selecciona el método de pago',
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Guardar Gasto',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
        currentIndex: 3,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          logger.i('Navegación inferior en AddExpenseScreen: $index');
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
        String hintText = '',
        TextInputType keyboardType = TextInputType.number,
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
            hintText: hintText,
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
      String hintText,
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
            hintText: hintText,
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
