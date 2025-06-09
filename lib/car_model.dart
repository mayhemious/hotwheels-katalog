// lib/car_model.dart
import 'dart:convert';

// Kategori 1 için enum
enum CarCategory1 {
  undefined, // Tanımsız
  racingCars,
  classicMuscleCars,
  offRoadSUV,
  superCars,
  electric,
  special, // Spacial -> Special olarak düzelttim, doğru kelime bu olmalı
  motorcycle, // Yeni eklendi
  other        // Yeni eklendi
}

// Kategori 2 için enum
enum CarCategory2 {
  regular,
  th, // Treasure Hunt
  sth // Super Treasure Hunt
}

// Enum'ları string'e ve string'den enum'a dönüştürmek için yardımcı fonksiyonlar
String carCategory1ToString(CarCategory1 category) => category.toString().split('.').last;
CarCategory1 carCategory1FromString(String? value) {
  if (value == null) return CarCategory1.undefined;
  return CarCategory1.values.firstWhere(
        (e) => e.toString().split('.').last == value,
        orElse: () => CarCategory1.undefined,
      );
}

String carCategory2ToString(CarCategory2 category) => category.toString().split('.').last;
CarCategory2 carCategory2FromString(String? value) {
  if (value == null) return CarCategory2.regular;
  return CarCategory2.values.firstWhere(
        (e) => e.toString().split('.').last == value,
        orElse: () => CarCategory2.regular,
      );
}


class Car {
  final String id;
  final String name;
  final String code;
  String? imagePath;
  final DateTime createdAt;
  CarCategory1 category1; // Kategori 1
  CarCategory2 category2; // Kategori 2

  Car({
    required this.id,
    required this.name,
    required this.code,
    this.imagePath,
    required this.createdAt,
    this.category1 = CarCategory1.undefined, // Varsayılan değer
    this.category2 = CarCategory2.regular,   // Varsayılan değer
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'category1': carCategory1ToString(category1), // Enum'ı string'e çevir
      'category2': carCategory2ToString(category2), // Enum'ı string'e çevir
    };
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      imagePath: map['imagePath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      category1: carCategory1FromString(map['category1'] as String?), // String'i enum'a çevir
      category2: carCategory2FromString(map['category2'] as String?), // String'i enum'a çevir
    );
  }

  String toJson() => json.encode(toMap());
  factory Car.fromJson(String source) => Car.fromMap(json.decode(source) as Map<String, dynamic>);

  // Kategori isimlerini daha kullanıcı dostu göstermek için (opsiyonel)
  String get category1DisplayName {
    switch (category1) {
      case CarCategory1.undefined: return 'Tanımsız';
      case CarCategory1.racingCars: return 'Racing Cars';
      case CarCategory1.classicMuscleCars: return 'Classic Muscle Cars';
      case CarCategory1.offRoadSUV: return 'Off-Road & SUV';
      case CarCategory1.superCars: return 'Super Cars';
      case CarCategory1.electric: return 'Electric';
      case CarCategory1.special: return 'Special';
      case CarCategory1.motorcycle: return 'Motorcycle';
      case CarCategory1.other: return 'Other';
      default: return 'Bilinmeyen';
    }
  }

  String get category2DisplayName {
    switch (category2) {
      case CarCategory2.regular: return 'Regular';
      case CarCategory2.th: return 'TH';
      case CarCategory2.sth: return 'STH';
      default: return 'Bilinmeyen';
    }
  }
}