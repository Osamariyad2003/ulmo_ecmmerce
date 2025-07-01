class PaymentIntentInputModel {
  final String amount;
  final String currency;
  String? customerId;

  PaymentIntentInputModel({
    required this.amount,
    required this.currency,
    this.customerId,
  });

  Map<String, dynamic> toJson() {
    final amountInCents = (double.parse(amount) * 100).toInt().toString();

    return {'amount': amountInCents, 'currency': currency};
  }
}
