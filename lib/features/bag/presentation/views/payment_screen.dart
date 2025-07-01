import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ulmo_ecmmerce/core/di/di.dart';
import 'package:ulmo_ecmmerce/core/helpers/stripe_services.dart';
import 'package:ulmo_ecmmerce/core/local/caches_keys.dart';
import 'package:ulmo_ecmmerce/core/models/payment_model/payment_intent_input_model.dart';
import 'package:ulmo_ecmmerce/features/bag/presentation/controller/bag_bloc.dart';
import 'package:ulmo_ecmmerce/features/bag/presentation/controller/bag_event.dart';
import 'package:ulmo_ecmmerce/features/bag/presentation/controller/bag_state.dart';
import 'package:ulmo_ecmmerce/features/delivery/data/model/delivery_model.dart';

class PaymentScreen extends StatelessWidget {
  final double total;

  const PaymentScreen({Key? key, required this.total}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BagBloc, BagState>(
            listener: (context, state) {
              if (state is PaymentSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment successful!')),
                );
                Navigator.pop(context);
              } else if (state is BagError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
          ),
        ],
        child: BlocBuilder<BagBloc, BagState>(
          builder: (context, state) {
            return PaymentViewBuilder(state: state, total: total);
          },
        ),
      ),
    );
  }
}

// Main payment view builder that handles conditional rendering
class PaymentViewBuilder extends StatelessWidget {
  final BagState state;
  final double total;

  const PaymentViewBuilder({Key? key, required this.state, required this.total})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // First check the state type
    if (state is BagLoaded) {
      // For loaded state, check the payment amount
      if (total <= 0) {
        return const EmptyCartView();
      } else if (total < 5.0) {
        return MinimumAmountView(total: total);
      } else {
        return PaymentMethodsView(bagState: state as BagLoaded, total: total);
      }
    } else if (state is PaymentProcessing) {
      return const PaymentProcessingView();
    } else {
      return const LoadingView();
    }
  }
}

// View for when the cart is empty
class EmptyCartView extends StatelessWidget {
  const EmptyCartView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Add items to your cart before checkout'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }
}

// View for when the payment amount is below minimum
class MinimumAmountView extends StatelessWidget {
  final double total;

  const MinimumAmountView({Key? key, required this.total}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            'Minimum order amount is \$5.00',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your current total: \$${total.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add More Items'),
          ),
        ],
      ),
    );
  }
}

// View for selecting payment methods and confirming payment
class PaymentMethodsView extends StatelessWidget {
  final BagLoaded bagState;
  final double total;

  const PaymentMethodsView({
    Key? key,
    required this.bagState,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.credit_card),
          title: const Text('Credit Card'),
          trailing: Radio(
            value: 'stripe',
            groupValue: context.read<BagBloc>().selectedPaymentMethod,
            onChanged: (value) {
              context.read<BagBloc>().add(
                SelectPaymentMethodEvent(value ?? "stripe"),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        PriceDetailsCard(total: total),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            // Fix the payment intent creation parameters
            context.read<BagBloc>().add(
              ConfirmPaymentEvent(
                deliveryInfo: DeliveryInfo(
                  address: 'Default Address',
                  userId: CacheKeys.cachedUserId ?? "guest",
                  method: "standard",
                  date: DateTime.now(),
                ),
                bag: bagState.bag,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Pay \$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

// Widget to display price details
class PriceDetailsCard extends StatelessWidget {
  final double total;

  const PriceDetailsCard({Key? key, required this.total}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate subtotal (assuming total includes tax)
    final subtotal = total / 1.1; // Example: 10% tax rate
    final tax = total - subtotal;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('\$${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax'),
                Text('\$${tax.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// View for processing payment
class PaymentProcessingView extends StatelessWidget {
  const PaymentProcessingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Processing payment...'),
        ],
      ),
    );
  }
}

// View for loading state
class LoadingView extends StatelessWidget {
  const LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
