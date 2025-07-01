import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:ulmo_ecmmerce/core/di/di.dart';
import 'package:ulmo_ecmmerce/core/helpers/api_keys.dart';
import 'package:ulmo_ecmmerce/core/local/caches_keys.dart';
import 'package:ulmo_ecmmerce/core/utils/widgets/custom_button.dart';
import 'package:ulmo_ecmmerce/features/bag/presentation/controller/bag_bloc.dart';
import 'package:ulmo_ecmmerce/features/bag/presentation/controller/bag_event.dart';
import 'package:ulmo_ecmmerce/features/bag/presentation/controller/bag_state.dart';
import 'package:ulmo_ecmmerce/features/delivery/presentation/views/address_list_screen.dart'
    show AddressListScreen;
import 'package:ulmo_ecmmerce/features/bag/presentation/views/payment_screen.dart';

import '../../data/model/delivery_model.dart';

import '../controller/delivery_bloc.dart';
import '../controller/delivery_event.dart';
import '../controller/delivery_state.dart';

// class AddressAutocompletePage extends StatefulWidget {
//   final String apiKey;
//   final Function(String description, double lat, double lng) onAddressSelected;

//   AddressAutocompletePage({
//     required this.apiKey,
//     required this.onAddressSelected,
//   });

//   @override
//   State<AddressAutocompletePage> createState() =>
//       AddressAutocompletePageState();
// }

// class AddressAutocompletePageState extends State<AddressAutocompletePage> {
//   final _controller = TextEditingController();
//   final _focusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     // Automatically focus the text field when the screen opens
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _focusNode.requestFocus();
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select delivery address'),
//         actions: [
//           // Add a close button in case the user wants to cancel
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             GooglePlaceAutoCompleteTextField(
//               textEditingController: _controller,
//               googleAPIKey: widget.apiKey,
//               focusNode: _focusNode, // Use the focus node to auto-focus
//               debounceTime: 600,
//               isLatLngRequired: true,
//               countries: ['JO'],
//               getPlaceDetailWithLatLng: (Prediction p) {
//                 widget.onAddressSelected(
//                   p.description ?? '',
//                   double.tryParse(p.lat ?? '0') ?? 0,
//                   double.tryParse(p.lng ?? '0') ?? 0,
//                 );
//                 Navigator.pop(context);
//               },
//               itemClick: (Prediction p) {
//                 _controller.text = p.description ?? '';
//                 _controller.selection = TextSelection.fromPosition(
//                   TextPosition(offset: _controller.text.length),
//                 );
//               },
//               inputDecoration: InputDecoration(
//                 labelText: 'Search address',
//                 hintText: 'Start typing to search...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 prefixIcon: const Icon(Icons.search),
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.clear),
//                   onPressed: () => _controller.clear(),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Enter your full address for delivery',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

class DeliveryScreen extends StatelessWidget {
  DeliveryScreen({Key? key}) : super(key: key);

  // Keep only one validation method
  bool _validateDeliveryInfo(DeliveryInfo deliveryInfo) {
    return deliveryInfo.address.isNotEmpty &&
        deliveryInfo.method.isNotEmpty &&
        deliveryInfo.date != null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di<DeliveryBloc>()),
        BlocProvider(create: (context) => di<BagBloc>()..add(LoadBagEvent())),
      ],
      child: BlocConsumer<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliveryError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final deliveryBloc = context.read<DeliveryBloc>();
          final deliveryInfo = deliveryBloc.currentDelivery;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Delivery Information'),
              backgroundColor: Colors.white,
            ),
            body:
                state is DeliveryLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state is DeliveryError && deliveryInfo == null
                    ? _buildEmptyDeliveryState(context)
                    : _buildDeliveryForm(context, deliveryInfo),
          );
        },
      ),
    );
  }

  Widget _buildEmptyDeliveryState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No delivery information found',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddressListScreen()),
              );
            },
            child: const Text('Add New Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryForm(BuildContext context, DeliveryInfo? deliveryInfo) {
    final bagState = context.watch<BagBloc>().state;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AddressSection(deliveryInfo: deliveryInfo),
          const SizedBox(height: 24),
          _buildMethodSection(context, deliveryInfo),
          const SizedBox(height: 24),
          _buildScheduleSection(context, deliveryInfo),
          const Spacer(),
          if (bagState is BagLoaded)
            ElevatedButton(
              onPressed: () {
                final deliveryBloc = context.read<DeliveryBloc>();
                final deliveryState = deliveryBloc.state;

                if (deliveryState is DeliverySelected) {
                  final deliveryInfo = DeliveryInfo(
                    address: deliveryState.address,
                    method: deliveryState.method,
                    date: deliveryState.date,
                    userId:
                        deliveryState.saved ? CacheKeys.cachedUserId : "guest",
                  );

                  if (_validateDeliveryInfo(deliveryInfo)) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MultiBlocProvider(
                              providers: [
                                BlocProvider.value(
                                  value: context.read<DeliveryBloc>(),
                                ),
                                BlocProvider.value(
                                  value: context.read<BagBloc>(),
                                ),
                              ],
                              child: PaymentScreen(
                                total:
                                    (context.read<BagBloc>().state as BagLoaded)
                                        .bag
                                        .total,
                              ),
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please complete delivery information.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Pay \$${(context.read<BagBloc>().state as BagLoaded).bag.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            )
          else
            const Text(
              'Failed to load bag details',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildMethodSection(BuildContext context, DeliveryInfo? deliveryInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DeliveryMethodSelector(
          selectedMethod: deliveryInfo?.method,
          onMethodSelected: (method) {
            context.read<DeliveryBloc>().add(SetDeliveryMethod(method));
          },
        ),
      ],
    );
  }

  Widget _buildScheduleSection(
    BuildContext context,
    DeliveryInfo? deliveryInfo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Schedule',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildDatePicker(context, deliveryInfo?.date),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildTimePicker(
                context,
                deliveryInfo?.date != null
                    ? TimeOfDay(
                      hour: deliveryInfo!.date!.hour,
                      minute: deliveryInfo.date!.minute,
                    )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, DateTime? date) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'Select Date',
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, TimeOfDay? time) {
    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(time != null ? _formatTimeOfDay(time) : 'Select Time'),
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final deliveryState = context.read<DeliveryBloc>().state;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && context.mounted) {
      context.read<DeliveryBloc>().add(
        SetDeliverySchedule(
          date,
          (deliveryState is DeliverySelected && deliveryState.date != null)
              ? TimeOfDay(
                hour: deliveryState.date!.hour,
                minute: deliveryState.date!.minute,
              )
              : TimeOfDay.now(),
        ),
      );
    }
  }

  void _selectTime(BuildContext context) async {
    final deliveryState = context.read<DeliveryBloc>().state;
    if (deliveryState is! DeliverySelected) return;

    final initialTime =
        deliveryState.date != null
            ? (deliveryState.date!.day == DateTime.now().day
                ? TimeOfDay.now()
                : const TimeOfDay(hour: 9, minute: 0))
            : TimeOfDay.now();

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null && context.mounted) {
      context.read<DeliveryBloc>().add(
        SetDeliverySchedule(deliveryState.date ?? DateTime.now(), time),
      );
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class AddressSection extends StatelessWidget {
  final DeliveryInfo? deliveryInfo;

  AddressSection({Key? key, this.deliveryInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        deliveryInfo?.address != null
            ? AddressCard(
              address: deliveryInfo!.address,
              onTapChange: () => _navigateToAddressPicker(context),
            )
            : AddressPickerNavigator(
              onAddressSelected: (selectedAddress) {
                // Update the state with the selected address
                context.read<DeliveryBloc>().add(
                  SelectSavedAddress(selectedAddress),
                );
              },
            ),
      ],
    );
  }

  void _navigateToAddressPicker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AddressPickerNavigator(onAddressSelected: (DeliveryInfo p1) {}),
      ),
    );
  }
}

class DeliveryMethodSelector extends StatelessWidget {
  final String? selectedMethod;
  final Function(String) onMethodSelected;

  const DeliveryMethodSelector({
    Key? key,
    this.selectedMethod,
    required this.onMethodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMethodTile(
          context,
          'standard',
          'Standard Delivery',
          '3-5 days',
          'Free',
        ),
        const SizedBox(height: 12),
        _buildMethodTile(
          context,
          'express',
          'Express Delivery',
          '1-2 days',
          '\$9.99',
        ),
      ],
    );
  }

  Widget _buildMethodTile(
    BuildContext context,
    String methodId,
    String title,
    String timeframe,
    String cost,
  ) {
    final isSelected = selectedMethod == methodId;
    return GestureDetector(
      onTap: () => onMethodSelected(methodId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? const Center(
                        child: Icon(Icons.check, size: 16, color: Colors.black),
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    timeframe,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              cost,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// New AddressPickerScreen for selecting an address
class SavedAddressPickerScreen extends StatelessWidget {
  const SavedAddressPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Address')),
      body: BlocBuilder<DeliveryBloc, DeliveryState>(
        builder: (context, state) {
          if (state is SavedAddressesLoaded) {
            return ListView.builder(
              itemCount: state.addresses.length,
              itemBuilder: (context, index) {
                final address = state.addresses[index];
                return ListTile(
                  title: Text(address.address),
                  onTap: () {
                    _selectAddress(context, address);
                  },
                );
              },
            );
          } else if (state is DeliveryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DeliveryError) {
            return Center(child: Text(state.message));
          } else {
            return const Center(child: Text('No addresses available.'));
          }
        },
      ),
    );
  }

  void _selectAddress(BuildContext context, DeliveryInfo address) {
    context.read<DeliveryBloc>().add(SelectSavedAddress(address));
    Navigator.pop(context);
  }
}

class AddressCard extends StatelessWidget {
  final String address;
  final VoidCallback onTapChange;

  const AddressCard({
    Key? key,
    required this.address,
    required this.onTapChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(address, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTapChange,
                child: const Text(
                  'Change Address',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddressPickerNavigator extends StatelessWidget {
  final Function(DeliveryInfo) onAddressSelected;

  const AddressPickerNavigator({Key? key, required this.onAddressSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final selectedAddress = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddressListScreen()),
        );

        if (selectedAddress != null && selectedAddress is DeliveryInfo) {
          // Pass the selected address back using the callback
          onAddressSelected(selectedAddress);
        }
      },
      child: const Text('Select Address'),
    );
  }
}

void _showAddressListScreen(BuildContext context) async {
  final selectedAddress = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => AddressListScreen()),
  );

  if (selectedAddress != null) {
    // Handle the selected address
    print('Selected Address: ${selectedAddress.address}');
    context.read<DeliveryBloc>().add(SelectSavedAddress(selectedAddress));
  }
}

// class AddressPickerScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Select Address')),
//       body: Center(child: const Text('Address Picker Screen')),
//     );
//   }
// }
