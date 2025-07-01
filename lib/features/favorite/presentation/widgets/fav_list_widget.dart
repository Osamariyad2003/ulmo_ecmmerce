import 'package:flutter/material.dart';
import 'package:ulmo_ecmmerce/features/favorite/presentation/widgets/product_fav_card.dart';
import 'package:ulmo_ecmmerce/features/product/presentation/widgets/product_details.dart';

class FavoritesListWidget extends StatelessWidget {
  final List<dynamic> products;
  final VoidCallback onRefresh;

  const FavoritesListWidget({
    Key? key,
    required this.products,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: Padding(
        padding: const EdgeInsets.all(15),
        child:
            products.isEmpty
                ? Center(
                  child: Text(
                    "Pull down to refresh favorites",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
                : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two items per row
                    childAspectRatio: 0.7, // Adjust this ratio as needed
                    crossAxisSpacing: 12, // Horizontal gap between items
                    mainAxisSpacing: 15, // Vertical gap between items
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Navigate to product details when card is tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ProductDetailsPage(
                                  product: products[index],
                                ),
                          ),
                        );
                      },
                      child: FavCard(product: products[index]),
                    );
                  },
                ),
      ),
    );
  }
}
