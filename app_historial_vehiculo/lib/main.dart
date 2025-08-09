// lib/main.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
// Importar todas las pantallas de Login
import 'package:app_historial_vehiculo/screens/Login/login.dart';
import 'package:app_historial_vehiculo/screens/Login/registro_screen.dart';
import 'package:app_historial_vehiculo/screens/Login/restablecer_pass.dart';
import 'package:app_historial_vehiculo/screens/Login/link_sent_screen.dart';
// Importar todas las pantallas de Dashboard
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/notifications_screen.dart';
// Importar todas las pantallas de Vehículos
import 'package:app_historial_vehiculo/screens/Vehiculos/one_add_vehicle_screen.dart' as initial_add_vehicle_screen;
import 'package:app_historial_vehiculo/screens/Vehiculos/add_vehicle_screen.dart' as general_add_vehicle_screen;
import 'package:app_historial_vehiculo/screens/Vehiculos/edit_vehicle_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/no_vehicles_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/vehicle_added_success_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/vehicle_detail_screen.dart';
import 'package:app_historial_vehiculo/screens/Vehiculos/changes_saved_screen.dart' as vehicle_changes_saved_screen;
// Importar todas las pantallas de Recordatorios
import 'package:app_historial_vehiculo/screens/Recordatorios/add_reminder_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_detail_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_deleted_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_completed_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_added_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/edit_reminder_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/delete_reminder_confirmation_screen.dart';
import 'package:app_historial_vehiculo/screens/Recordatorios/reminder_saved_screen.dart';
// Importar todas las pantallas de Mantenimiento
import 'package:app_historial_vehiculo/screens/Mantenimiento/add_maintenance_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/changes_saved_success_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/delete_maintenance_confirmation_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/Detail_mantenance_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/edit_maintenance_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_added_success_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_completed_success_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart';
import 'package:app_historial_vehiculo/screens/Mantenimiento/no_maintenance_screen.dart';
// Importar todas las pantallas de Gastos
import 'package:app_historial_vehiculo/screens/Gastos/add_expense_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/changes_saved_screen.dart' as expense_changes_saved_screen;
import 'package:app_historial_vehiculo/screens/Gastos/confirm_delete_expense_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/edit_expense_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expense_added_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expense_deleted_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expense_detail_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart';
import 'package:app_historial_vehiculo/screens/Gastos/no_expenses_screen.dart';
// Importar todas las pantallas de Perfil
import 'package:app_historial_vehiculo/screens/Perfil/account_deleted_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/authentication_method_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/change_password_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/delete_account_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/documents_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/help_support_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/logout_confirmation_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/notification_settings_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/personal_info_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/privacy_policy_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/recovery_codes_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/security_privacy_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/terms_conditions_screen.dart';
import 'package:app_historial_vehiculo/screens/Perfil/two_factor_auth_screen.dart';
// Importar los modelos (¡CRUCIAL para resolver errores de tipo!)
import 'package:app_historial_vehiculo/models/reminder.dart';
import 'package:app_historial_vehiculo/models/vehicle.dart';
import 'package:app_historial_vehiculo/models/maintenance.dart';


var logger = Logger(
  printer: PrettyPrinter(),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Apphvehicular());
}

class Apphvehicular extends StatelessWidget {
  const Apphvehicular({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos dummy para pasar a las pantallas que requieren argumentos
    final dummyExpenseData = {
      'id': 'e1',
      'tipo': 'Combustible',
      'fecha': '15/03/2024',
      'monto': '\$55.00',
      'vehiculo': 'Ford Focus',
      'description': 'Llenado del tanque',
      'metodoPago': 'Efectivo',
    };

    final dummyReminder = Reminder(
      id: 'rem_dummy',
      title: 'Cambio de Aceite (Dummy)',
      description: 'Recordatorio dummy para prueba.',
      vehicle: 'Toyota Corolla',
      vehicleId: 'veh_dummy',
      date: '20/10/2024',
      time: '09:00 AM',
      status: 'Pendiente',
    );

    final dummyVehicle = Vehicle(
      id: 'veh_dummy',
      imageUrl: 'https://placehold.co/150x150/0000FF/FFFFFF?text=Dummy+Car',
      name: 'Honda',
      brandModel: 'Civic',
      year: 2018,
      plate: 'XYZ 789',
      color: 'Gris',
      mileage: 80000,
    );

    final dummyMaintenanceData = Maintenance(
      id: 'm_dummy',
      tipoMantenimiento: 'Revisión General (Dummy)',
      vehiculo: 'Nissan Sentra',
      vehicleId: 'veh_dummy',
      fecha: DateTime(2024, 11, 5),
      kilometraje: 95000,
      costo: 150.00,
      estado: 'Pendiente',
      tallerResponsable: 'Taller Rápido',
      descripcion: 'Revisión completa de fluidos y sistema eléctrico.',
    );


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VehículoApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      initialRoute: '/login',
      routes: {
        // Login Module
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
        '/link_sent': (context) => const LinkSentScreen(),

        // Dashboard Module
        '/home': (context) => const HomeScreen(),
        '/notifications': (context) => const NotificationsScreen(),

        // Vehicle Module
        '/one_add_vehicle': (context) => const initial_add_vehicle_screen.AddVehicleScreen(),
        '/add_vehicle': (context) => const general_add_vehicle_screen.AddVehicleScreen(),
        '/edit_vehicle': (context) => EditVehicleScreen(vehicle: dummyVehicle),
        '/no_vehicles': (context) => const NoVehiclesScreen(),
        '/vehicle_added_success': (context) => const VehicleAddedSuccessScreen(),
        '/vehicle_detail': (context) => VehicleDetailScreen(vehicle: dummyVehicle),
        '/vehicle_changes_saved': (context) => const vehicle_changes_saved_screen.ChangesSavedScreen(),

        // Reminder Module
        '/add_reminder': (context) => const AddReminderScreen(),
        '/reminder_detail': (context) => ReminderDetailScreen(reminder: dummyReminder),
        '/reminder_deleted': (context) => const ReminderDeletedScreen(deletedReminderId: 'dummy_id', deletedReminderTitle: 'Título Eliminado'),
        '/reminder_completed': (context) => ReminderCompletedScreen(completedReminder: dummyReminder),
        '/reminder_added': (context) => ReminderAddedScreen(addedReminder: dummyReminder),
        '/edit_reminder': (context) => EditReminderScreen(reminder: dummyReminder),
        '/delete_reminder_confirmation': (context) => const DeleteReminderConfirmationScreen(),
        '/reminder_saved': (context) => ReminderSavedScreen(addedReminder: dummyReminder),

        // Maintenance Module
        '/add_maintenance': (context) => const AddMaintenanceScreen(),
        '/maintenance_changes_saved_success': (context) => const ChangesSavedSuccessScreen(),
        // **CORREGIDO**
        '/delete_maintenance_confirmation': (context) => DeleteMaintenanceConfirmationScreen(maintenance: dummyMaintenanceData.toFirestore()),
        '/maintenance_detail': (context) => MaintenanceDetailScreen(id: dummyMaintenanceData.id, maintenance: dummyMaintenanceData),
        '/edit_maintenance': (context) => EditMaintenanceScreen(maintenance: dummyMaintenanceData),
        '/maintenance_added_success': (context) => const MaintenanceAddedSuccessScreen(),
        // **CORREGIDO**
        '/maintenance_completed_success': (context) => const MaintenanceCompletedSuccessScreen(),
        '/maintenance_list': (context) => const MaintenanceListScreen(),
        '/no_maintenance': (context) => const NoMaintenanceScreen(),

        // Expense Module
        '/add_expense': (context) => const AddExpenseScreen(),
        '/expense_changes_saved': (context) => expense_changes_saved_screen.ChangesSavedScreen(expense: dummyExpenseData),
        '/confirm_delete_expense': (context) => ConfirmDeleteExpenseScreen(expense: dummyExpenseData),
        '/edit_expense': (context) => EditExpenseScreen(expense: dummyExpenseData),
        '/expense_added': (context) => ExpenseAddedScreen(expense: dummyExpenseData),
        '/expense_deleted': (context) => ExpenseDeletedScreen(expense: dummyExpenseData),
        '/expense_detail': (context) => ExpenseDetailScreen(expense: dummyExpenseData),
        '/expenses': (context) => const ExpensesScreen(),
        '/no_expenses': (context) => const NoExpensesScreen(),

        // Profile Module
        '/account_deleted': (context) => const AccountDeletedScreen(),
        '/authentication_method': (context) => const AuthenticationMethodScreen(),
        '/change_password': (context) => const ChangePasswordScreen(),
        '/delete_account': (context) => const DeleteAccountScreen(),
        '/documents': (context) => const DocumentsScreen(),
        '/help_support': (context) => const HelpSupportScreen(),
        '/logout_confirmation': (context) => const LogoutConfirmationScreen(),
        '/notification_settings': (context) => const NotificationSettingsScreen(),
        '/personal_info': (context) => const PersonalInfoScreen(),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/recovery_codes': (context) => const RecoveryCodesScreen(),
        '/security_privacy': (context) => const SecurityPrivacyScreen(),
        '/terms_conditions': (context) => const TermsConditionsScreen(),
        '/two_factor_auth': (context) => const TwoFactorAuthScreen(),
      },
    );
  }
}