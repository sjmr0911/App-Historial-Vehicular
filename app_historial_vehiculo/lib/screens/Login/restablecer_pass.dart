// lib/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:app_historial_vehiculo/screens/Login/link_sent_screen.dart'; // Importar la pantalla de Link Enviado (LinkSentScreen)
import 'package:logger/logger.dart'; // Asegúrate de tener esta dependencia
import 'package:firebase_auth/firebase_auth.dart'; // Importar Firebase Auth

// Reutilizamos la instancia de logger
var logger = Logger(
  printer: PrettyPrinter(),
);

class ResetPasswordScreen extends StatefulWidget { // Cambiado a StatefulWidget
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instancia de FirebaseAuth
  // Added form key for validation
  final _formKey = GlobalKey<FormState>(); // NEW: Add a GlobalKey for form validation


  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Método para enviar el enlace de restablecimiento de contraseña
  Future<void> _sendPasswordResetEmail() async {
    // NEW: Add form validation check
    if (_formKey.currentState!.validate()) {
      try {
        // Muestra un indicador de carga
        if (mounted) { // Added mounted check
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enviando enlace...')),
          );
        }

        await _auth.sendPasswordResetEmail(email: _emailController.text.trim());

        // Si el envío es exitoso, navega a la pantalla de "Enlace Enviado"
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Oculta el SnackBar de carga
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LinkSentScreen()),
          );
          logger.i('Enlace de restablecimiento enviado a: ${_emailController.text}');
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Oculta el SnackBar de carga
        }
        String message;
        if (e.code == 'user-not-found') {
          message = 'No se encontró ningún usuario con ese correo electrónico.';
        } else if (e.code == 'invalid-email') {
          message = 'El formato del correo electrónico es inválido.';
        } else if (e.code == 'network-request-failed') {
          message = 'Error de conexión. Por favor, verifica tu internet.';
        } else {
          message = 'Error al enviar enlace: ${e.message}';
        }
        logger.e('Error al enviar enlace de restablecimiento: ${e.code} - ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } catch (e) {
        if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Oculta el SnackBar de carga
        }
        logger.e('Error inesperado al enviar enlace de restablecimiento: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ocurrió un error inesperado: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form( // NEW: Wrap with Form widget
            key: _formKey, // NEW: Assign form key
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Botón Volver
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      logger.i('Se hizo clic en "Volver" desde Restablecer Contraseña');
                      // Navega de vuelta a la pantalla de Login.
                      Navigator.pop(context); // Vuelve a la pantalla anterior
                    },
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
                    label: const Text(
                      'Volver',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Icono de candado
                const Icon(
                  Icons.lock_reset,
                  color: Color(0xFF1E88E5), // Color azul
                  size: 100,
                ),
                const SizedBox(height: 30),

                // Título "Restablecer Contraseña"
                const Text(
                  'Restablecer Contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // Mensaje de instrucción
                Text(
                  'Ingresa tu correo electrónico para recibir un enlace para restablecer tu contraseña.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 30),

                // Campo de Correo Electrónico
                TextFormField( // Changed to TextFormField for validation
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) { // NEW: Add validator
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu correo';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30), // Espacio antes del botón

                // Botón "Enviar Enlace"
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sendPasswordResetEmail, // Llama al método para enviar el email
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5), // Color azul del botón
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0), // Bordes redondeados
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Enviar Enlace',
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
      ),
    );
  }
}
