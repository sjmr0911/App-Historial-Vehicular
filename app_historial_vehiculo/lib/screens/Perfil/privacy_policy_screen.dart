// lib/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // Para el BottomNavigationBar


var logger = Logger(printer: PrettyPrinter());

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // Método para manejar la navegación inferior
  void _handleBottomNavigation(BuildContext context, int index) {
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
            logger.i('Volver desde Política de Privacidad');
            Navigator.pop(context); // Vuelve a SecurityPrivacyScreen
          },
        ),
        title: const Text(
          'Política de Privacidad',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Esta Política de Privacidad describe cómo se recopila, usa y comparte su información personal cuando visita o realiza una compra en la aplicación.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Recopilación de Información Personal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Cuando visita la aplicación, recopilamos automáticamente cierta información sobre su dispositivo, incluida información sobre su navegador web, dirección IP, zona horaria y algunas de las cookies que están instaladas en su dispositivo. Además, a medida que navega por la aplicación, recopilamos información sobre las páginas web o productos individuales que ve, qué sitios web o términos de búsqueda lo remitieron a la aplicación e información sobre cómo interactúa con la aplicación. Nos referimos a esta información recopilada automáticamente como "Información del Dispositivo".',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Text(
              'También recopilamos información personal que usted nos proporciona directamente, como su nombre, dirección de correo electrónico, número de teléfono y detalles del vehículo cuando se registra en la aplicación, añade un vehículo, programa un mantenimiento o registra un gasto. A esta información la llamamos "Información del Usuario".',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '2. Uso de su Información Personal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Utilizamos la Información del Dispositivo y la Información del Usuario que recopilamos para:',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 5),
            Text(
              '• Proporcionar y mantener el servicio de la aplicación, incluyendo la gestión de sus vehículos, mantenimientos, gastos y recordatorios.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              '• Personalizar su experiencia y ofrecerle contenido y funciones relevantes.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              '• Mejorar y optimizar nuestra aplicación (por ejemplo, generando análisis sobre cómo nuestros clientes navegan e interactúan con la aplicación).',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              '• Comunicarnos con usted, incluyendo el envío de notificaciones y alertas relacionadas con su vehículo o la aplicación.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              '• Detectar y prevenir fraudes y otras actividades maliciosas.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '3. Compartir su Información Personal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'No compartimos su Información Personal con terceros, excepto cuando sea necesario para operar la aplicación, cumplir con las leyes y regulaciones aplicables, responder a una citación, una orden de registro u otra solicitud legal de información que recibamos, o para proteger nuestros derechos.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '4. Sus Derechos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Usted tiene derecho a acceder a la información personal que tenemos sobre usted y a solicitar que su información personal sea corregida, actualizada o eliminada. Si desea ejercer este derecho, contáctenos a través de la información de contacto a continuación.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '5. Seguridad de los Datos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Tomamos medidas razonables para proteger la información personal de nuestros usuarios contra el acceso no autorizado, la alteración, la divulgación o la destrucción. Sin embargo, ninguna transmisión de datos por Internet o método de almacenamiento electrónico es 100% seguro.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '6. Cambios en esta Política de Privacidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Podemos actualizar esta política de privacidad de vez en cuando para reflejar, por ejemplo, cambios en nuestras prácticas o por otras razones operativas, legales o reglamentarias.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '7. Contáctenos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Para obtener más información sobre nuestras prácticas de privacidad, si tiene preguntas o si desea presentar una queja, contáctenos por correo electrónico a soporte@vehiculoapp.com.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 40),
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
        currentIndex: 4, // Perfil
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          logger.i('Navegación inferior en PrivacyPolicyScreen: $index');
          _handleBottomNavigation(context, index);
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}