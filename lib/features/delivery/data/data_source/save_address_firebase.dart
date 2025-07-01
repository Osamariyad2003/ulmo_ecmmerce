import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ulmo_ecmmerce/features/delivery/data/model/delivery_model.dart';

class SaveAddressFirebase {
  final FirebaseFirestore _firestore;

  SaveAddressFirebase({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveAddress({
    required String userId,
    required String savedAddress,
  }) async {
    try {
      await _firestore.collection('places').add({
        'userId': userId ?? "",
        'savedaddress': savedAddress,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save address: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAddresses(String userId) async {
    try {
      // Modify the query to handle the case when the index doesn't exist
      QuerySnapshot querySnapshot;
      try {
        // Try with orderBy - this requires the composite index
        querySnapshot = await _firestore.collection('places').get();
      } catch (indexError) {
        // If index error occurs, fall back to simpler query without ordering
        print('Index error: $indexError - Using simple query without ordering');
        querySnapshot =
            await _firestore
                .collection('places')
                .where('userId', isEqualTo: userId)
                .get();
      }

      return querySnapshot.docs
          .map(
            (doc) => <String, dynamic>{
              'id': doc.id,
              ...?doc.data() as Map<String, dynamic>,
            },
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get addresses: $e');
    }
  }

  Future<void> updateAddress({
    required String addressId,
    String? savedAddress,
    double? lat,
    double? lng,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (savedAddress != null) updates['savedaddress'] = savedAddress;
      if (lat != null) updates['lat'] = lat;
      if (lng != null) updates['lng'] = lng;

      await _firestore.collection('places').doc(addressId).update(updates);
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _firestore.collection('places').doc(addressId).delete();
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  Future<List<DeliveryInfo>> getSavedAddresses(String? userId) async {
    Query query = _firestore.collection('addresses');
    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return DeliveryInfo.fromMap(data);
    }).toList();
  }
}
