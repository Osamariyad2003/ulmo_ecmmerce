import 'package:flutter/material.dart';
import 'package:ulmo_ecmmerce/features/delivery/data/model/delivery_model.dart';

abstract class DeliveryState {
  const DeliveryState();
}

// Add new state for saved addresses
class SavedAddressesLoaded extends DeliveryState {
  final List<DeliveryInfo> addresses;
  const SavedAddressesLoaded(this.addresses);
}

class DeliveryInitial extends DeliveryState {
  const DeliveryInitial();
}

class DeliveryLoading extends DeliveryState {
  const DeliveryLoading();
}

class DeliveryError extends DeliveryState {
  final String message;

  const DeliveryError(this.message);
}

class DeliverySelected extends DeliveryState {
  final String address;
  final String method;
  final DateTime date;
  final bool saved;

  const DeliverySelected({
    required this.address,
    required this.method,
    required this.date,
    this.saved = false,
  });

  DeliverySelected copyWith({
    String? address,
    String? method,
    DateTime? date,
    bool? saved,
  }) {
    return DeliverySelected(
      address: address ?? this.address,
      method: method ?? this.method,
      date: date ?? this.date,
      saved: saved ?? this.saved,
    );
  }
}
