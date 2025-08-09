import 'package:flutter/material.dart';
import 'package:app_historial_vehiculo/screens/Login/login.dart'; // Importar la pantalla de login (LoginScreen)
import 'package:logger/logger.dart'; // Asegúrate de tener esta dependencia


// Reutilizamos la instancia de logger
var logger = Logger(
  printer: PrettyPrinter(),
);

class LinkSentScreen extends StatelessWidget {
  const LinkSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Icono de checkmark
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green, // Color verde para el check
                size: 100, // Tamaño del icono
              ),
              const SizedBox(height: 30),

              // Título "Enlace Enviado"
              const Text(
                'Enlace Enviado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Mensaje de confirmación
              Text(
                'Hemos enviado un enlace a tu correo electrónico para restablecer tu contraseña. Por favor, revisa tu bandeja de entrada (y la carpeta de spam).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 40),

              // Botón "Volver al Inicio de Sesión"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    logger.i('Se hizo clic en "Volver al Inicio de Sesión"');
                    // Vuelve al inicio de sesión y elimina todas las rutas anteriores
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()), // Redirige a LoginScreen
                      (Route<dynamic> route) => false, // Elimina todas las rutas de la pila
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5), // Color azul del botón
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0), // Bordes redondeados
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Volver al Inicio de Sesión',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
