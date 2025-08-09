// lib/models/vehicle.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String id;
  final String name;
  final String brandModel;
  final int year;
  final String plate;
  final String color; // <-- ¡Nuevo campo añadido!
  final String imageUrl;
  final int mileage;

  Vehicle({
    required this.id,
    required this.name,
    required this.brandModel,
    required this.year,
    required this.plate,
    required this.color, // <-- ¡Nuevo parámetro requerido!
    required this.imageUrl,
    required this.mileage,
  });

  // CORRECCIÓN: Ahora el constructor de fábrica acepta DocumentSnapshot<Object?>
  factory Vehicle.fromFirestore(DocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return Vehicle(
        id: doc.id,
        name: 'Sin nombre',
        brandModel: 'Sin modelo',
        year: 0,
        plate: 'N/A',
        color: '', // <-- Se añade un valor por defecto
        imageUrl: '',
        mileage: 0,
      );
    }

    return Vehicle(
      id: doc.id,
      name: data['name'] as String? ?? 'Sin nombre',
      brandModel: data['brandModel'] as String? ?? 'Sin modelo',
      year: (data['year'] as num?)?.toInt() ?? 0,
      plate: data['plate'] as String? ?? 'N/A',
      color: data['color'] as String? ?? '', // <-- Se mapea el valor de Firestore
      imageUrl: data['imageUrl'] as String? ?? '',
      mileage: (data['mileage'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brandModel': brandModel,
      'year': year,
      'plate': plate,
      'color': color, // <-- Se añade al mapa para guardar en Firestore
      'imageUrl': imageUrl,
      'mileage': mileage,
    };
  }
}