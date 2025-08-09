// lib/models/reminder.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final String title;
  final String description; // Este es el campo que usas para las "notas"
  final String vehicle;
  final String vehicleId;
  final String date;
  final String time;
  final String status;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.vehicle,
    required this.vehicleId,
    required this.date,
    required this.time,
    required this.status,
  });

  factory Reminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return Reminder(
      id: doc.id,
      title: data?['title'] ?? 'Sin título',
      description: data?['description'] ?? '',
      vehicle: data?['vehicle'] ?? 'Sin vehículo',
      vehicleId: data?['vehicleId'] ?? '',
      date: data?['date'] ?? '',
      time: data?['time'] ?? '',
      status: data?['status'] ?? 'Pendiente',
    );
  }

  // Método para crear una copia del objeto con nuevos valores
  Reminder copyWith({
    String? title,
    String? description,
    String? vehicle,
    String? vehicleId,
    String? date,
    String? time,
    String? status,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      vehicle: vehicle ?? this.vehicle,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'vehicle': vehicle,
      'vehicleId': vehicleId,
      'date': date,
      'time': time,
      'status': status,
    };
  }
}


