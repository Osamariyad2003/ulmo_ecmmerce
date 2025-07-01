import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeliveryInfo {
  final String userId;
  final String address;

  final String method;
  final DateTime date;

  DeliveryInfo({
    required this.userId,
    required this.address,
    required this.method,
    required this.date,
  });

  factory DeliveryInfo.fromMap(Map<String, dynamic> map) {
    return DeliveryInfo(
      address: map['savedaddress'] ?? '',
      method: map['method'] ?? '',
      date:
          map['createdAt'] != null && map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp)
                  .toDate() // Convert Firestore Timestamp to DateTime
              : DateTime.now(),
      userId: map['userId'] ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'address': address,

      'method': method,
      'date': date.toIso8601String(),
    };
  }
}
