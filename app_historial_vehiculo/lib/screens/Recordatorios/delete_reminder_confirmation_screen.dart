import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
// No se necesita importar reminder_detail_screen.dart aquí ya que Navigator.pop maneja el retorno.

var logger = Logger(printer: PrettyPrinter());

class DeleteReminderConfirmationScreen extends StatelessWidget {
  const DeleteReminderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            logger.i('Cancelar eliminación (AppBar)');
            // Indicar cancelación a la pantalla anterior (ReminderDetailScreen)
            Navigator.pop(context, false); // False significa que se canceló
          },
        ),
        title: const Text(
          'Eliminar Recordatorio',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 100,
              ),
              const SizedBox(height: 30),
              const Text(
                '¿Estás seguro que deseas eliminar este recordatorio?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Esta acción no se puede deshacer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    logger.i('Confirmar eliminación (botón Eliminar)');
                    // Indicar confirmación a la pantalla anterior
                    Navigator.pop(context, true); // True significa que se confirmó
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    logger.i('Cancelar eliminación (botón)');
                    // Indicar cancelación a la pantalla anterior
                    Navigator.pop(context, false); // False significa que se canceló
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
