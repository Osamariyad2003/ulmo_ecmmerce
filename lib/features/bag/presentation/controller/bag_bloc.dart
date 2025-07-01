import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ulmo_ecmmerce/core/helpers/stripe_services.dart';
import 'package:ulmo_ecmmerce/core/local/caches_keys.dart';
import 'package:ulmo_ecmmerce/core/models/payment_model/initPaymentSheetInputModel.dart';
import 'package:ulmo_ecmmerce/core/models/payment_model/payment_intent_input_model.dart';
import 'package:ulmo_ecmmerce/features/bag/domain/usecases/pay_usecase.dart';
import 'package:ulmo_ecmmerce/features/bag/domain/usecases/update_item_usecase.dart';
import 'package:ulmo_ecmmerce/features/bag/presentation/controller/bag_event.dart';
import 'package:ulmo_ecmmerce/features/bag/presentation/controller/bag_state.dart';
import 'package:ulmo_ecmmerce/features/delivery/data/model/delivery_model.dart';
import 'package:ulmo_ecmmerce/features/delivery/presentation/controller/delivery_state.dart';
import '../../domain/usecases/add_item_usecase.dart';
import '../../domain/usecases/remove_item_usecase.dart';
import '../../domain/usecases/get_bag_usecase.dart';
import '../../domain/usecases/clear_bag_usecase.dart';
import '../../data/models/bag_item_model.dart';
import 'package:ulmo_ecmmerce/features/delivery/presentation/controller/delivery_bloc.dart';

class BagBloc extends Bloc<BagEvent, BagState> {
  final AddItemToBagUseCase addItemUseCase;
  final RemoveItemFromBagUseCase removeItemUseCase;
  final GetBagUseCase getBagUseCase;
  final ClearBagUseCase clearBagUseCase;
  final UpdateBagItemQuantityUseCase updateBagItemQuantityUseCase;
  final PayUseCase processPaymentUseCase;
  final DeliveryBloc deliveryBloc;

  String? selectedPaymentMethod;

  BagBloc({
    required this.addItemUseCase,
    required this.removeItemUseCase,
    required this.updateBagItemQuantityUseCase,
    required this.getBagUseCase,
    required this.clearBagUseCase,
    required this.processPaymentUseCase,
    required this.deliveryBloc,
  }) : super(BagLoading()) {
    on<LoadBagEvent>(_onLoadBag);
    on<AddQuantityEvent>(_onAddQuantity);
    on<RemoveQuantityEvent>(_onRemoveQuantity);
    on<RemoveItemEvent>(_onRemoveItem);
    // on<ApplyPromoEvent>(_onApplyPromo);
    on<ClearBagEvent>(_onClearBag);
    on<SelectPaymentMethodEvent>(_onSelectPaymentMethod);
    on<ConfirmPaymentEvent>(_onConfirmPayment);
    on<AddItemEvent>(_onAddItem);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
  }

  Future<void> _emitLoaded(Emitter<BagState> emit) async {
    try {
      final bag = await getBagUseCase.call();
      emit(BagLoaded(bag: bag, selectedPaymentMethod: selectedPaymentMethod));
    } catch (e) {
      emit(BagError("Failed to load bag: ${e.toString()}"));
    }
  }

  void _onLoadBag(LoadBagEvent event, Emitter<BagState> emit) {
    _emitLoaded(emit);
  }

  Future<void> _onAddQuantity(
    AddQuantityEvent event,
    Emitter<BagState> emit,
  ) async {
    try {
      final bag = await getBagUseCase.call();
      final itemIndex = bag.items.indexWhere(
        (e) =>
            e.productId.trim().toLowerCase() ==
            event.productId.trim().toLowerCase(),
      );

      if (itemIndex != -1) {
        final item = bag.items[itemIndex];
        updateBagItemQuantityUseCase.call(item.productId, item.quantity + 1);
        await _emitLoaded(emit);
      } else {
        emit(BagError("Item not found in bag"));
      }
    } catch (e) {
      emit(BagError("Failed to add quantity: ${e.toString()}"));
    }
  }

  Future<void> _onRemoveQuantity(
    RemoveQuantityEvent event,
    Emitter<BagState> emit,
  ) async {
    try {
      final bag = await getBagUseCase.call();
      final itemIndex = bag.items.indexWhere(
        (e) =>
            e.productId.trim().toLowerCase() ==
            event.productId.trim().toLowerCase(),
      );

      if (itemIndex != -1) {
        final item = bag.items[itemIndex];
        final newQty = item.quantity > 1 ? item.quantity - 1 : 1;
        updateBagItemQuantityUseCase.call(event.productId, newQty);
        await _emitLoaded(emit);
      } else {
        emit(BagError("Item not found in bag"));
      }
    } catch (e) {
      emit(BagError("Failed to remove quantity: ${e.toString()}"));
    }
  }

  Future<void> _onAddItem(AddItemEvent event, Emitter<BagState> emit) async {
    try {
      final newItem = BagItemModel(
        productId: event.item.productId.trim(),
        name: event.item.name,
        price: event.item.price,
        imageUrl: event.item.imageUrl,
      );
      addItemUseCase.call(newItem);
      await _emitLoaded(emit);
    } catch (e) {
      emit(BagError("Failed to add item: ${e.toString()}"));
    }
  }

  Future<void> _onRemoveItem(
    RemoveItemEvent event,
    Emitter<BagState> emit,
  ) async {
    try {
      removeItemUseCase.call(event.productId);
      await _emitLoaded(emit);
    } catch (e) {
      emit(BagError("Failed to remove item: ${e.toString()}"));
    }
  }

  Future<void> _onUpdateQuantity(
    UpdateQuantityEvent event,
    Emitter<BagState> emit,
  ) async {
    try {
      updateBagItemQuantityUseCase.call(event.productId, event.quantity);
      await _emitLoaded(emit);
    } catch (e) {
      emit(BagError("Failed to update quantity: ${e.toString()}"));
    }
  }

  // Future<void> _onApplyPromo(ApplyPromoEvent event, Emitter<BagState> emit) async {
  //   try {
  //     await applyPromoUseCase.execute(event.promoCode);
  //     await _emitLoaded(emit);
  //   } catch (e) {
  //     emit(BagError("Failed to apply promo: ${e.toString()}"));
  //   }
  // }

  Future<void> _onClearBag(ClearBagEvent event, Emitter<BagState> emit) async {
    try {
      clearBagUseCase.call();
      await _emitLoaded(emit);
    } catch (e) {
      emit(BagError("Failed to clear bag: ${e.toString()}"));
    }
  }

  void _onSelectPaymentMethod(
    SelectPaymentMethodEvent event,
    Emitter<BagState> emit,
  ) {
    try {
      selectedPaymentMethod = event.methodId;
      _emitLoaded(emit);
    } catch (e) {
      emit(BagError("Failed to select payment method: ${e.toString()}"));
    }
  }

  Future<void> _onConfirmPayment(
    ConfirmPaymentEvent event,
    Emitter<BagState> emit,
  ) async {
    if (selectedPaymentMethod == null) {
      emit(BagError("Please select a payment method."));
      return;
    }

    emit(PaymentProcessing());
    try {
      final stripeServices = StripeServices();
      String customerId;

      // Check if we have a user ID
      if (CacheKeys.cachedUserId != null) {
        // Use cached user ID or create a new customer
        customerId = CacheKeys.cachedUserId!;
      } else {
        // Create a guest customer with a random email
        String randomEmail = "guest_${Random().nextInt(10000)}@example.com";
        try {
          // Create a real Stripe customer for guests
          customerId = await stripeServices.createStripeCustomer(randomEmail);
        } catch (e) {
          print("Failed to create customer: $e");
          // Fallback to guest checkout without customer ID
          customerId = "guest";
        }
      }

      // Ensure amount is in cents (integer)
      final amount = (event.bag.total * 100).round().toString();

      // Create payment intent
      final paymentIntentInputModel = PaymentIntentInputModel(
        amount: amount,
        currency: 'usd',
        customerId: customerId,
      );

      final paymentIntentModel = await stripeServices.createPaymentIntent(
        paymentIntentInputModel,
      );

      // For guest checkout or fallback, skip ephemeral key
      if (customerId == "guest") {
        // Simple checkout without customer
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentModel.clientSecret!,
            merchantDisplayName: 'Osama',
          ),
        );
      } else {
        // Try to create ephemeral key for valid customers
        try {
          final ephemeralKey = await stripeServices.createEphemeralkey(
            customerId: customerId,
          );

          // Initialize payment sheet with customer data
          final initPaymentSheetInputModel = Initpaymentsheetinputmodel(
            clientSecret: paymentIntentModel.clientSecret!,
            ephemeralKeySecret: ephemeralKey.secret!,
            customerId: customerId,
          );

          await stripeServices.initpaymentsheet(
            initpaymentsheetinputModel: initPaymentSheetInputModel,
          );
        } catch (e) {
          print("Error with customer flow, falling back to guest checkout: $e");
          // Fallback to guest checkout
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntentModel.clientSecret!,
              merchantDisplayName: 'Osama',
            ),
          );
        }
      }

      // Display payment sheet
      await stripeServices.displayPaymentSheet();

      // Clear bag and reset payment method
      clearBagUseCase.call();
      selectedPaymentMethod = null;

      emit(PaymentSuccess());
    } catch (e) {
      print("Payment error details: $e");
      emit(BagError("Payment failed: ${e.toString()}"));
    }
  }

  bool _isDeliveryInfoComplete(DeliveryInfo deliveryInfo) {
    return deliveryInfo.address.isNotEmpty &&
        deliveryInfo.method.isNotEmpty &&
        deliveryInfo.date != null;
  }
}
