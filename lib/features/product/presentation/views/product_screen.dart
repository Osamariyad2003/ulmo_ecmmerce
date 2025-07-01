import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ulmo_ecmmerce/core/themes/colors_style.dart';
import 'package:ulmo_ecmmerce/features/categories/presentation/widgets/search_field.dart'
    hide SearchField;
import 'package:ulmo_ecmmerce/features/product/domain/usecases/fetch_products.dart';
import 'package:ulmo_ecmmerce/features/product/presentation/controller/product_event.dart';
import 'package:ulmo_ecmmerce/features/product/presentation/widgets/fliter_screen.dart';
import 'package:ulmo_ecmmerce/features/product/presentation/widgets/product_details.dart';
import '../../../../core/di/di.dart';
import '../../../../core/models/product.dart';
import '../../../bag/presentation/controller/bag_bloc.dart';
import '../../../favorite/presentation/controller/favorite_bloc.dart';
import '../controller/product_bloc.dart';
import '../controller/product_state.dart';
import '../widgets/product_card.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/search_field.dart';

class ProductScreen extends StatelessWidget {
  final String? parentCategory;
  final String? parentid;

  const ProductScreen({Key? key, this.parentCategory, this.parentid})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive calculations
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine grid columns based on screen width
    final int crossAxisCount = screenWidth > 600 ? 3 : 2;

    // Calculate child aspect ratio based on screen size
    final double childAspectRatio = screenWidth > 600 ? 0.8 : 0.7;

    return Builder(
      builder: (innerContext) {
        // Schedule the product loading after build
        Future.microtask(() {
          innerContext.read<ProductBloc>().add(
            LoadProductsEvent(parentid ?? ""),
          );
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(
              parentCategory ?? "",
              style: TextStyle(fontSize: 18.sp),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  children: [
                    SearchField(onChanged: (value) {}),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // Handle sort action
                          },
                          icon: const Icon(Icons.sort, size: 16),
                          label: const Text('Sort'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FilterScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.filter_alt, size: 16),
                          label: Text('Filter'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ProductLoaded) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return GridView.builder(
                            padding: EdgeInsets.all(16.r),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      constraints.maxWidth > 600 ? 3 : 2,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing: 12.r,
                                  mainAxisSpacing: 12.r,
                                ),
                            itemCount: state.products.length,
                            itemBuilder:
                                (context, index) => ProductCard(
                                  product: state.products[index],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => MultiBlocProvider(
                                              providers: [
                                                BlocProvider.value(
                                                  value:
                                                      context
                                                          .read<ProductBloc>(),
                                                ),
                                                BlocProvider.value(
                                                  value:
                                                      context
                                                          .read<FavoriteBloc>(),
                                                ),
                                                BlocProvider.value(
                                                  value:
                                                      context.read<BagBloc>(),
                                                ),
                                              ],
                                              child: ProductDetailsPage(
                                                product: state.products[index],
                                              ),
                                            ),
                                      ),
                                    );
                                  },
                                ),
                          );
                        },
                      );
                    } else if (state is ProductError) {
                      return Center(child: Text(state.message));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
