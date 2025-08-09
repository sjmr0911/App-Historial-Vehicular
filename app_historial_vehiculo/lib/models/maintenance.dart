// lib/models/maintenance.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Maintenance {
  final String id;
  final String tipoMantenimiento;
  final String vehiculo;
  final String vehicleId;
  final DateTime fecha;
  final String? tallerResponsable;
  final int kilometraje;
  final double costo;
  final String? descripcion;
  final String estado;

  Maintenance({
    required this.id,
    required this.tipoMantenimiento,
    required this.vehiculo,
    required this.vehicleId,
    required this.fecha,
    this.tallerResponsable,
    required this.kilometraje,
    required this.costo,
    this.descripcion,
    required this.estado,
  });

  /// Crea una copia de este objeto con los campos actualizados.
  Maintenance copyWith({
    String? id,
    String? tipoMantenimiento,
    String? vehiculo,
    String? vehicleId,
    DateTime? fecha,
    String? tallerResponsable,
    int? kilometraje,
    double? costo,
    String? descripcion,
    String? estado,
  }) {
    return Maintenance(
      id: id ?? this.id,
      tipoMantenimiento: tipoMantenimiento ?? this.tipoMantenimiento,
      vehiculo: vehiculo ?? this.vehiculo,
      vehicleId: vehicleId ?? this.vehicleId,
      fecha: fecha ?? this.fecha,
      tallerResponsable: tallerResponsable ?? this.tallerResponsable,
      kilometraje: kilometraje ?? this.kilometraje,
      costo: costo ?? this.costo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
    );
  }

  /// Convierte el objeto a un mapa para guardarlo en Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'tipoMantenimiento': tipoMantenimiento,
      'vehiculo': vehiculo,
      'vehicleId': vehicleId,
      'fecha': fecha,
      'tallerResponsable': tallerResponsable,
      'kilometraje': kilometraje,
      'costo': costo,
      'descripcion': descripcion,
      'estado': estado,
    };
  }

  /// Crea un objeto `Maintenance` a partir de un documento de Firestore.
  factory Maintenance.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return Maintenance(
      id: snapshot.id,
      tipoMantenimiento: data?['tipoMantenimiento'] ?? '',
      vehiculo: data?['vehiculo'] ?? '',
      vehicleId: data?['vehicleId'] ?? '',
      fecha: (data?['fecha'] as Timestamp).toDate(),
      tallerResponsable: data?['tallerResponsable'],
      kilometraje: data?['kilometraje'] ?? 0,
      costo: (data?['costo'] as num?)?.toDouble() ?? 0.0,
      descripcion: data?['descripcion'],
      estado: data?['estado'] ?? 'Pendiente',
    );
  }
}