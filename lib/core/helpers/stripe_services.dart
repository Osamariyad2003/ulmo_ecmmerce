import 'package:dio/dio.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../models/payment_model/initPaymentSheetInputModel.dart';
import '../models/payment_model/payment_intent_input_model.dart';
import '../models/payment_model/payment_intent_model/ephemeral_key_model/ephermeraLkey_model.dart';
import '../models/payment_model/payment_intent_model/payment_intent_model.dart';
import 'api_keys.dart';
import 'api_services.dart';

class StripeServices {
  final ApiServices _apiServices = ApiServices();

  Future<PaymentIntentModel> createPaymentIntent(
    PaymentIntentInputModel paymentIntentInputModel,
  ) async {
    try {
      // Log what we're sending
      print(
        'Creating payment intent with data: ${paymentIntentInputModel.toJson()}',
      );

      final response = await _apiServices.post(
        url: 'https://api.stripe.com/v1/payment_intents',
        data: paymentIntentInputModel.toJson(),
        headers: {
          'Authorization': 'Bearer ${APIKeys.secertKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        options: Options(),
      );

      print('Stripe response: ${response.data}');
      return PaymentIntentModel.fromJson(response.data);
    } catch (e) {
      // Log detailed error
      if (e is DioException) {
        print('DioError: ${e.response?.statusCode}');
        print('Error response data: ${e.response?.data}');
      }
      print('Error creating payment intent: $e');
      throw Exception('Payment intent creation failed: ${e.toString()}');
    }
  }

  Future<void> initpaymentsheet({
    required Initpaymentsheetinputmodel initpaymentsheetinputModel,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: initpaymentsheetinputModel.clientSecret,
          merchantDisplayName: 'Osama',
          // Only include customer parameters if we have a real customer ID
          // If using a guest customer, omit these fields
          customerId:
              initpaymentsheetinputModel.customerId != "guest"
                  ? initpaymentsheetinputModel.customerId
                  : null,
          customerEphemeralKeySecret:
              initpaymentsheetinputModel.customerId != "guest"
                  ? initpaymentsheetinputModel.ephemeralKeySecret
                  : null,
        ),
      );
    } catch (e) {
      print('Error initializing payment sheet: $e');
      throw Exception('Payment sheet initialization failed: ${e.toString()}');
    }
  }

  Future<void> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      print('Error displaying payment sheet: $e');
      throw Exception('Display payment sheet failed: ${e.toString()}');
    }
  }

  Future<void> makePayment({
    required PaymentIntentInputModel paymentIntentInputModel,
  }) async {
    try {
      // Create payment intent first
      final paymentIntentModel = await createPaymentIntent(
        paymentIntentInputModel,
      );

      // For guest checkout, we can skip the ephemeral key creation
      if (paymentIntentInputModel.customerId == null ||
          paymentIntentInputModel.customerId == "guest") {
        // Initialize payment sheet without customer data
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentModel.clientSecret!,
            merchantDisplayName: 'Osama',
            // Skip customer fields for guest checkout
          ),
        );
      } else {
        // For registered users, create ephemeral key and use complete setup
        final ephemeralKey = await createEphemeralkey(
          customerId: paymentIntentInputModel.customerId!,
        );

        await initpaymentsheet(
          initpaymentsheetinputModel: Initpaymentsheetinputmodel(
            clientSecret: paymentIntentModel.clientSecret!,
            ephemeralKeySecret: ephemeralKey.secret!,
            customerId: paymentIntentInputModel.customerId!,
          ),
        );
      }

      // Present the payment sheet
      await displayPaymentSheet();
    } catch (e) {
      print('Error making payment: $e');
      throw Exception('Payment failed: ${e.toString()}');
    }
  }

  Future<String> createStripeCustomer(String email, {String? name}) async {
    try {
      final response = await _apiServices.post(
        url: 'https://api.stripe.com/v1/customers',
        data: {'email': email, if (name != null) 'name': name},
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer ${APIKeys.secertKey}',
        },
        options: Options(),
      );

      print('Customer creation response: ${response.data}');
      return response.data['id'];
    } catch (e) {
      print('Error creating Stripe customer: $e');
      throw Exception('Customer creation failed: ${e.toString()}');
    }
  }

  Future<EphemeralKeyModel> createEphemeralkey({
    required String customerId,
  }) async {
    try {
      // Validate customer ID
      if (customerId.isEmpty || customerId == "guest") {
        throw Exception(
          "Valid Stripe customer ID is required for creating ephemeral key",
        );
      }

      print('Creating ephemeral key for customer ID: $customerId');

      // Clean up duplicate headers declaration
      final response = await _apiServices.post(
        url: 'https://api.stripe.com/v1/ephemeral_keys',
        data: {"customer": customerId},
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer ${APIKeys.secertKey}',
          'Stripe-Version': '2023-08-16', // Make sure this is up to date
        },
        options: Options(),
      );

      print('Ephemeral key response: ${response.data}');

      return EphemeralKeyModel.fromJson(response.data);
    } catch (e) {
      print('Error creating ephemeral key: $e');
      throw Exception('Ephemeral key creation failed: ${e.toString()}');
    }
  }
}
