// lib/terms_conditions_screen.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:app_historial_vehiculo/screens/Dashboard/home_screen.dart'; // Para BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Vehiculos/my_vehicles_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Mantenimiento/maintenance_list_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Gastos/expenses_screen.dart'; // Para el BottomNavigationBar
import 'package:app_historial_vehiculo/screens/Perfil/profile_screen.dart'; // Para el BottomNavigationBar


var logger = Logger(printer: PrettyPrinter());

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
            logger.i('Volver desde Términos y Condiciones');
            Navigator.pop(context); // Vuelve a SecurityPrivacyScreen
          },
        ),
        title: const Text(
          'Términos y Condiciones',
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
              'Bienvenido a nuestra aplicación. Al acceder o utilizar nuestra aplicación, usted acepta estar sujeto a estos Términos y Condiciones. Si no está de acuerdo con alguna parte de los términos, no podrá acceder a la aplicación.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Uso de la Aplicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Usted acepta utilizar la aplicación solo para fines lícitos y de una manera que no infrinja los derechos de, restrinja o inhiba el uso y disfrute de la aplicación por parte de cualquier tercero. El comportamiento prohibido incluye acosar o causar angustia o inconvenientes a cualquier otra persona, transmitir contenido obsceno u ofensivo o interrumpir el flujo normal de diálogo dentro de la aplicación.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '2. Propiedad Intelectual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Todos los derechos de autor, marcas registradas, derechos de diseño, patentes y otros derechos de propiedad intelectual (registrados y no registrados) en y sobre la aplicación y todo el contenido ubicado en la aplicación seguirán siendo propiedad de [Nombre de la Empresa/Desarrollador] o sus licenciantes (que pueden incluir a otros usuarios).',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '3. Cuentas de Usuario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Al crear una cuenta con nosotros, usted garantiza que tiene más de 18 años y que la información que nos proporciona es precisa, completa y actual en todo momento. La información inexacta, incompleta u obsoleta puede resultar en la terminación inmediata de su cuenta en la aplicación.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '4. Enlaces a Otros Sitios Web',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Nuestra aplicación puede contener enlaces a sitios web o servicios de terceros que no son propiedad ni están controlados por [Nombre de la Empresa/Desarrollador]. No tenemos control ni asumimos ninguna responsabilidad por el contenido, las políticas de privacidad o las prácticas de los sitios web o servicios de terceros. Le recomendamos encarecidamente que lea los términos y condiciones y las políticas de privacidad de cualquier sitio web o servicio de terceros que visite.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '5. Terminación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Podemos terminar o suspender su cuenta y prohibirle el acceso a la aplicación de inmediato, sin previo aviso ni responsabilidad, bajo nuestro exclusivo criterio, por cualquier motivo y sin limitación, incluido, entre otros, el incumplimiento de los Términos.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '6. Limitación de Responsabilidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'La aplicación se proporciona "tal cual" y "según disponibilidad" sin ninguna representación o respaldo y sin garantía de ningún tipo, ya sea expresa o implícita, incluidas, entre otras, las garantías implícitas de calidad satisfactoria, idoneidad para un propósito particular, no infracción, compatibilidad, seguridad y precisión.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '7. Cambios en los Términos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Nos reservamos el derecho de modificar estos Términos y Condiciones en cualquier momento. Al continuar utilizando la aplicación después de cualquier modificación, usted acepta estar sujeto a los Términos y Condiciones revisados.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              '8. Contáctenos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'Si tiene alguna pregunta sobre estos Términos y Condiciones, puede contactarnos a través de soporte@vehiculoapp.com.',
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
          logger.i('Navegación inferior en TermsConditionsScreen: $index');
          _handleBottomNavigation(context, index);
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
