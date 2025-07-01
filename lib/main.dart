import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ulmo_ecmmerce/core/app_router/app_router.dart';
import 'package:ulmo_ecmmerce/core/app_router/routers.dart';
import 'package:ulmo_ecmmerce/core/helpers/api_keys.dart';
import 'package:ulmo_ecmmerce/core/helpers/bloc_observer.dart';
import 'package:ulmo_ecmmerce/features/bag/presentation/controller/bag_event.dart';
import 'package:ulmo_ecmmerce/features/delivery/presentation/controller/delivery_bloc.dart';
import 'package:ulmo_ecmmerce/features/profile/presentation/controller/profile_bloc.dart';
import 'package:ulmo_ecmmerce/features/profile/presentation/controller/profile_event.dart';

import 'core/di/di.dart';
import 'core/themes/app_theme.dart';
import 'features/bag/presentation/controller/bag_bloc.dart';
import 'features/favorite/presentation/controller/favorite_bloc.dart';
import 'features/layout/presentation/controller/layout_bloc.dart';
import 'features/product/presentation/controller/product_bloc.dart';
import 'features/profile/data/models/credit_card.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Bloc.observer = MyBlocObserver();

  Stripe.publishableKey = APIKeys.publishableKey;
  await Stripe.instance.applySettings();

  setupServiceLocator();
  await Hive.initFlutter();
  await Hive.openBox('appBox');
  await Hive.openBox<CreditCard>('payment_cards');
  await Hive.openBox<List<String>>('favorite_ids');
  await Hive.openBox('bag_box');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => di<LayoutBloc>()),
            BlocProvider(create: (_) => di<ProductBloc>()),
            BlocProvider(
              create: (_) {
                final bagBloc = di<BagBloc>();
                bagBloc.add(LoadBagEvent());
                return bagBloc;
              },
            ),
            BlocProvider(create: (_) => di<FavoriteBloc>()),
            BlocProvider(create: (_) => di<ProfileBloc>()..add(LoadProfile())),
            BlocProvider(create: (context) => di<DeliveryBloc>()),
          ],
          child: MaterialApp(
            onGenerateRoute: AppRouter.onGenerateRoute,
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            initialRoute: Routes.splash,
          ),
        );
      },
    );
  }
}
