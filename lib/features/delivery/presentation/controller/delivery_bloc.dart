import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:ulmo_ecmmerce/core/local/caches_keys.dart';
import 'package:ulmo_ecmmerce/features/delivery/data/repo/delivery_repository.dart';
import 'package:ulmo_ecmmerce/features/delivery/presentation/controller/delivery_event.dart';
import '../../data/model/delivery_model.dart';
import 'delivery_state.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final DeliveryRepository repository;
  DeliveryInfo? deliveryInfo;
  List<DeliveryInfo> _savedAddresses = [];

  DeliveryInfo? get currentDelivery => deliveryInfo;
  List<DeliveryInfo> get savedAddresses => _savedAddresses;

  DeliveryBloc({required DeliveryRepository D_repository})
    : repository = D_repository,
      super(DeliveryInitial()) {
    // Register events
    on<LoadSavedAddresses>(_onLoadSavedAddresses);
    on<SaveNewAddress>(_onSaveNewAddress);
    on<DeleteSavedAddress>(_onDeleteSavedAddress);
    on<SelectSavedAddress>(_onSelectSavedAddress);
    on<SetDeliveryAddress>(_onSetDeliveryAddress);
    on<SetDeliveryMethod>(_onSetDeliveryMethod);
    on<SetDeliverySchedule>(_onSetDeliverySchedule);
  }

  void _onSetDeliveryAddress(
    SetDeliveryAddress event,
    Emitter<DeliveryState> emit,
  ) {
    try {
      deliveryInfo = DeliveryInfo(
        userId: CacheKeys.cachedUserId ?? "guest",
        address: event.address,
        method: deliveryInfo?.method ?? 'standerd',
        date: deliveryInfo?.date ?? DateTime.now(),
      );

      emit(
        DeliverySelected(
          address: deliveryInfo?.address ?? "",
          method: deliveryInfo?.method ?? "",
          date: deliveryInfo?.date ?? DateTime.now(),
        ),
      );
    } catch (e) {
      emit(DeliveryError('Failed to set address: ${e.toString()}'));
    }
  }

  void _onSetDeliveryMethod(
    SetDeliveryMethod event,
    Emitter<DeliveryState> emit,
  ) {
    try {
      if (deliveryInfo == null) {
        emit(DeliveryError('Please set delivery address first'));
        return;
      }

      deliveryInfo = DeliveryInfo(
        userId: deliveryInfo!.userId,
        address: deliveryInfo!.address,
        method: event.method,
        date: deliveryInfo!.date,
      );

      emit(
        DeliverySelected(
          address: deliveryInfo!.address,
          method: deliveryInfo!.method,
          date: deliveryInfo!.date,
        ),
      );
    } catch (e) {
      emit(DeliveryError('Failed to set delivery method: ${e.toString()}'));
    }
  }

  void _onSetDeliverySchedule(
    SetDeliverySchedule event,
    Emitter<DeliveryState> emit,
  ) {
    try {
      if (deliveryInfo == null) {
        emit(DeliveryError('Please set delivery address first'));
        return;
      }

      deliveryInfo = DeliveryInfo(
        userId: deliveryInfo!.userId,
        address: deliveryInfo!.address,
        method: deliveryInfo!.method,
        date: event.date ?? DateTime.now(),
      );

      emit(
        DeliverySelected(
          address: deliveryInfo!.address,
          method: deliveryInfo!.method,
          date: deliveryInfo!.date,
        ),
      );
    } catch (e) {
      emit(DeliveryError('Failed to set delivery schedule: ${e.toString()}'));
    }
  }

  Future<void> _onLoadSavedAddresses(
    LoadSavedAddresses event,
    Emitter<DeliveryState> emit,
  ) async {
    try {
      emit(DeliveryLoading());

      // Fetch saved addresses
      _savedAddresses = await repository.getSavedAddresses(event.userId);

      // Check for empty data
      if (_savedAddresses.isEmpty) {
        // Instead of emitting an error, emit a state that indicates no addresses
        emit(
          SavedAddressesLoaded(_savedAddresses),
        ); // Empty list but not an error
        return;
      }

      // Select the first address as default if we have any
      if (_savedAddresses.isNotEmpty && deliveryInfo == null) {
        deliveryInfo = _savedAddresses.first;
        emit(
          DeliverySelected(
            address: deliveryInfo!.address,
            method: deliveryInfo!.method,
            date: deliveryInfo!.date,
            saved: true,
          ),
        );
      } else {
        // Just emit the loaded state
        emit(SavedAddressesLoaded(_savedAddresses));
      }
    } on FormatException catch (e) {
      // Handle data format errors
      emit(DeliveryError('Data format error: ${e.message}'));
    } catch (e) {
      // Handle any other errors
      emit(DeliveryError('Failed to load saved addresses: ${e.toString()}'));
    }
  }

  Future<void> _onSaveNewAddress(
    SaveNewAddress event,
    Emitter<DeliveryState> emit,
  ) async {
    try {
      emit(DeliveryLoading());

      await repository.saveDeliveryInfo(
        DeliveryInfo(
          userId: event.userId,
          address: event.address,
          method: deliveryInfo?.method ?? '',
          date: deliveryInfo?.date ?? DateTime.now(),
        ),
      );

      _savedAddresses = await repository.getSavedAddresses(event.userId);
      emit(SavedAddressesLoaded(_savedAddresses));
    } catch (e) {
      emit(DeliveryError('Failed to save new address: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteSavedAddress(
    DeleteSavedAddress event,
    Emitter<DeliveryState> emit,
  ) async {
    try {
      emit(DeliveryLoading());
      await repository.deleteDeliveryInfo(event.addressId);
      _savedAddresses.removeWhere(
        (address) => address.address == event.addressId,
      );
      emit(SavedAddressesLoaded(_savedAddresses));
    } catch (e) {
      emit(DeliveryError('Failed to delete address: ${e.toString()}'));
    }
  }

  void _onSelectSavedAddress(
    SelectSavedAddress event,
    Emitter<DeliveryState> emit,
  ) {
    try {
      deliveryInfo = event.address;
      emit(
        DeliverySelected(
          address: deliveryInfo!.address,
          method: deliveryInfo!.method,
          date: deliveryInfo!.date,
        ),
      );
    } catch (e) {
      emit(DeliveryError('Failed to select address: ${e.toString()}'));
    }
  }

  void selectDeliveryInfo(DeliveryInfo deliveryInfo) {
    if (_isDeliveryInfoComplete(deliveryInfo)) {
      emit(
        DeliverySelected(
          address: deliveryInfo.address,
          method: deliveryInfo.method,
          date: deliveryInfo.date,
          saved: true,
        ),
      );
    } else {
      emit(DeliveryError("Incomplete delivery information."));
    }
  }

  bool _isDeliveryInfoComplete(DeliveryInfo deliveryInfo) {
    return deliveryInfo.address.isNotEmpty &&
        deliveryInfo.method.isNotEmpty &&
        deliveryInfo.date != null;
  }
}
