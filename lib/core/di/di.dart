import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ulmo_ecmmerce/core/helpers/stripe_services.dart';
import 'package:ulmo_ecmmerce/features/auth/data/repo/auth_repo.dart';
import 'package:ulmo_ecmmerce/features/auth/domain/usecases/login_google_usecase.dart';
import 'package:ulmo_ecmmerce/features/auth/domain/usecases/login_usecase.dart';
import 'package:ulmo_ecmmerce/features/auth/presentation/controller/otp_bloc/otp_bloc.dart';
import 'package:ulmo_ecmmerce/features/auth/presentation/controller/register_bloc/register_bloc.dart';
import 'package:ulmo_ecmmerce/features/bag/data/data_source/bag_data_source.dart';
import 'package:ulmo_ecmmerce/features/bag/data/data_source/payment_data_source.dart';
import 'package:ulmo_ecmmerce/features/bag/data/repo/bag_repo.dart';
import 'package:ulmo_ecmmerce/features/bag/data/repo/payment_repo.dart';
import 'package:ulmo_ecmmerce/features/bag/presentation/controller/bag_bloc.dart';
import 'package:ulmo_ecmmerce/features/categories/data/data_source/category_data_source.dart';
import 'package:ulmo_ecmmerce/features/categories/data/repo/category_repo_impl.dart';
import 'package:ulmo_ecmmerce/features/categories/domain/usecases/fetch_categories.dart';
import 'package:ulmo_ecmmerce/features/categories/domain/usecases/fetch_child_categories.dart';
import 'package:ulmo_ecmmerce/features/categories/presentation/controller/category_bloc.dart';
import 'package:ulmo_ecmmerce/features/delivery/data/data_source/save_address_firebase.dart';
import 'package:ulmo_ecmmerce/features/delivery/data/repo/delivery_repository.dart';
import 'package:ulmo_ecmmerce/features/delivery/presentation/controller/delivery_bloc.dart';
import 'package:ulmo_ecmmerce/features/favorite/presentation/controller/favorite_bloc.dart';
import 'package:ulmo_ecmmerce/features/layout/presentation/controller/layout_bloc.dart';
import 'package:ulmo_ecmmerce/features/product/data/data_source/filter_data_source.dart';
import 'package:ulmo_ecmmerce/features/product/data/data_source/product_data_source.dart';
import 'package:ulmo_ecmmerce/features/product/data/repo/product_repo.dart';
import 'package:ulmo_ecmmerce/features/product/domain/usecases/fetch_all_products.dart';
import 'package:ulmo_ecmmerce/features/product/domain/usecases/fetch_products.dart';
import 'package:ulmo_ecmmerce/features/product/presentation/controller/product_bloc.dart';
import 'package:ulmo_ecmmerce/features/profile/data/data_source/profile_data_source.dart';
import 'package:ulmo_ecmmerce/features/profile/data/repo/profile_repo.dart';
import 'package:ulmo_ecmmerce/features/profile/domain/usecases/change_password_usecase.dart';
import 'package:ulmo_ecmmerce/features/profile/domain/usecases/delete_payment_method_usecase.dart';
import 'package:ulmo_ecmmerce/features/profile/domain/usecases/get_payment_methods_usecase.dart';
import 'package:ulmo_ecmmerce/features/profile/domain/usecases/get_user_orders_usecase.dart';
import 'package:ulmo_ecmmerce/features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:ulmo_ecmmerce/features/profile/domain/usecases/save_payment_method_usecase.dart';
import 'package:ulmo_ecmmerce/features/profile/domain/usecases/set_default_payment_method_usecase.dart';
import 'package:ulmo_ecmmerce/features/profile/domain/usecases/sign_out_usecase.dart';
import 'package:ulmo_ecmmerce/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:ulmo_ecmmerce/features/profile/domain/usecases/upload_profile_photo_usecase.dart';
import 'package:ulmo_ecmmerce/features/profile/presentation/controller/profile_bloc.dart';
import 'package:ulmo_ecmmerce/features/review/data/data_source/review_data_source.dart';
import 'package:ulmo_ecmmerce/features/review/data/data_source/user_data_source.dart';
import 'package:ulmo_ecmmerce/features/review/data/repo/review_repo.dart';
import 'package:ulmo_ecmmerce/features/review/domain/usecases/get_prodect_review.dart';
import 'package:ulmo_ecmmerce/features/review/domain/usecases/submit_review_usecases.dart';
import 'package:ulmo_ecmmerce/features/review/presentation/controller/review_%20bloc.dart';
import '../../features/profile/data/data_source/local_data_source/card_data_source.dart';

import '../../features/auth/data/data_source/firebase_auth_data_source.dart';
import '../../features/auth/domain/usecases/otp_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/controller/login_bloc/login_bloc.dart';
import '../../features/bag/domain/usecases/add_item_usecase.dart';
import '../../features/bag/domain/usecases/clear_bag_usecase.dart';
import '../../features/bag/domain/usecases/get_bag_usecase.dart';
import '../../features/bag/domain/usecases/pay_usecase.dart';
import '../../features/bag/domain/usecases/remove_item_usecase.dart';
import '../../features/bag/domain/usecases/update_item_usecase.dart';
import '../../features/product/domain/usecases/filter_usecase.dart';
import '../models/product.dart';

final GetIt di = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Initialize Hive
  await Hive.initFlutter();

  //data source
  di.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSource(),
  );

  di.registerLazySingleton<CategoryDataSource>(() => CategoryDataSource());

  di.registerLazySingleton<ProductDataSource>(() => ProductDataSource());

  di.registerLazySingleton<FilterDataSource>(() => FilterDataSource());
  di.registerLazySingleton<ReviewDataSource>(() => ReviewDataSource());
  di.registerLazySingleton<UserDataSource>(() => UserDataSource());

  di.registerLazySingleton<BagDataSource>(() => BagDataSource());

  di.registerLazySingleton<StripeServices>(() => StripeServices());

  di.registerLazySingleton<PaymentDataSource>(
    () => PaymentDataSource(
      bagSource: di<BagDataSource>(),
      stripeServises: di<StripeServices>(),
      stripeCustomerId: '',
    ),
  );
  di.registerLazySingleton<ProfileDataSource>(() => ProfileDataSource());
  di.registerLazySingleton<SaveAddressFirebase>(() => SaveAddressFirebase());

  // Register HiveCardStorage
  final cardStorage = await HiveCardStorage.create();
  di.registerSingleton<HiveCardStorage>(cardStorage);

  //repo
  di.registerLazySingleton<AuthRepositoryImpl>(
    () => AuthRepositoryImpl(
      firebaseAuth: FirebaseAuth.instance,
      secureStorage: FlutterSecureStorage(),
      googleSignIn: GoogleSignIn(),
    ),
  );

  di.registerLazySingleton<CategoriesRepo>(
    () => CategoriesRepo(categoryDataSource: di<CategoryDataSource>()),
  );

  di.registerLazySingleton<ProductsRepo>(
    () => ProductsRepo(
      filterDataSource: di<FilterDataSource>(),
      productsDataSource: di<ProductDataSource>(),
    ),
  );

  di.registerLazySingleton<ReviewRepository>(
    () => ReviewRepository(di<ReviewDataSource>(), di<UserDataSource>()),
  );

  di.registerLazySingleton<PaymentRepositoryImpl>(
    () => PaymentRepositoryImpl(paymentDataSource: di<PaymentDataSource>()),
  );
  di.registerLazySingleton<BagRepositoryImpl>(
    () => BagRepositoryImpl(bagDataSource: di<BagDataSource>()),
  );

  di.registerLazySingleton<ProfileRepo>(
    () => ProfileRepo(
      profileDataSource: di<ProfileDataSource>(),
      cardLocalSource: di<HiveCardStorage>(),
    ),
  );
  di.registerLazySingleton<DeliveryRepository>(
    () => DeliveryRepository(addressDataSource: di.get<SaveAddressFirebase>()),
  );

  //use cases
  di.registerLazySingleton<RegisterUserUseCase>(
    () => RegisterUserUseCase(di.get<AuthRepositoryImpl>()),
  );

  di.registerLazySingleton<LoginWithEmailUseCase>(
    () => LoginWithEmailUseCase(di.get<AuthRepositoryImpl>()),
  );
  di.registerLazySingleton<LoginWithGoogleUseCase>(
    () => LoginWithGoogleUseCase(di.get<AuthRepositoryImpl>()),
  );
  di.registerLazySingleton<VerifyOtpUseCase>(
    () => VerifyOtpUseCase(di.get<AuthRepositoryImpl>()),
  );

  di.registerLazySingleton<FetchCategoriesUseCase>(
    () => FetchCategoriesUseCase(di.get<CategoriesRepo>()),
  );

  di.registerLazySingleton<FetchChildCategoriesUseCase>(
    () => FetchChildCategoriesUseCase(di.get<CategoriesRepo>()),
  );

  di.registerLazySingleton<FetchProductsUseCase>(
    () => FetchProductsUseCase(di.get<ProductsRepo>()),
  );
  di.registerLazySingleton<FilterProductsUseCase>(
    () => FilterProductsUseCase(di.get<ProductsRepo>()),
  );
  di.registerLazySingleton<FetchCategoriesFilterUseCase>(
    () => FetchCategoriesFilterUseCase(di.get<ProductsRepo>()),
  );
  di.registerLazySingleton<SubmitReview>(
    () => SubmitReview(di.get<ReviewRepository>()),
  );
  di.registerLazySingleton<GetProductReviews>(
    () => GetProductReviews(di.get<ReviewRepository>()),
  );

  di.registerLazySingleton<AddItemToBagUseCase>(
    () => AddItemToBagUseCase(di.get<BagRepositoryImpl>()),
  );
  di.registerLazySingleton<ClearBagUseCase>(
    () => ClearBagUseCase(di.get<BagRepositoryImpl>()),
  );

  di.registerLazySingleton<GetBagUseCase>(
    () => GetBagUseCase(di.get<BagRepositoryImpl>()),
  );

  di.registerLazySingleton<RemoveItemFromBagUseCase>(
    () => RemoveItemFromBagUseCase(di.get<BagRepositoryImpl>()),
  );

  di.registerLazySingleton<UpdateBagItemQuantityUseCase>(
    () => UpdateBagItemQuantityUseCase(di.get<BagRepositoryImpl>()),
  );

  di.registerLazySingleton<PayUseCase>(
    () => PayUseCase(di.get<PaymentRepositoryImpl>()),
  );

  di.registerLazySingleton<GetUserProfileUseCase>(
    () => GetUserProfileUseCase(di.get<ProfileRepo>()),
  );
  di.registerLazySingleton<GetUserOrdersUseCase>(
    () => GetUserOrdersUseCase(di.get<ProfileRepo>()),
  );
  di.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(di.get<ProfileRepo>()),
  );
  di.registerLazySingleton<UploadProfilePhotoUseCase>(
    () => UploadProfilePhotoUseCase(di.get<ProfileRepo>()),
  );
  di.registerLazySingleton<ChangePasswordUseCase>(
    () => ChangePasswordUseCase(di.get<ProfileRepo>()),
  );
  di.registerLazySingleton<UpdateProfileUseCase>(
    () => UpdateProfileUseCase(di.get<ProfileRepo>()),
  );
  di.registerLazySingleton<DeletePaymentMethodUseCase>(
    () => DeletePaymentMethodUseCase(di.get<ProfileRepo>()),
  );
  di.registerLazySingleton<GetPaymentMethodsUseCase>(
    () => GetPaymentMethodsUseCase(di.get<ProfileRepo>()),
  );
  di.registerLazySingleton<SavePaymentMethodUseCase>(
    () => SavePaymentMethodUseCase(di.get<ProfileRepo>()),
  );
  di.registerLazySingleton<SetDefaultPaymentMethodUseCase>(
    () => SetDefaultPaymentMethodUseCase(di.get<ProfileRepo>()),
  );

  //  blocs
  di.registerLazySingleton<RegisterBloc>(
    () => RegisterBloc(di.get<RegisterUserUseCase>()),
  );

  di.registerLazySingleton<OtpAuthBloc>(
    () => OtpAuthBloc(di.get<VerifyOtpUseCase>()),
  );
  di.registerLazySingleton<LoginBloc>(
    () => LoginBloc(
      di.get<LoginWithEmailUseCase>(),
      di.get<LoginWithGoogleUseCase>(),
    ),
  );
  di.registerFactory<LayoutBloc>(() => LayoutBloc());
  di.registerFactory<CategoryBloc>(
    () => CategoryBloc(
      di.get<FetchCategoriesUseCase>(),
      di.get<FetchChildCategoriesUseCase>(),
      di.get<CategoriesRepo>(),
    ),
  );
  di.registerFactory<ProductBloc>(
    () => ProductBloc(
      di.get<FetchProductsUseCase>(),
      di.get<FilterProductsUseCase>(),
      di.get<FetchCategoriesFilterUseCase>(),
    ),
  );

  di.registerFactory<ReviewBloc>(
    () => ReviewBloc(
      submitReview: di.get<SubmitReview>(),
      getProductReviews: di.get<GetProductReviews>(),
    ),
  );
  di.registerFactory<FavoriteBloc>(
    () => FavoriteBloc(productRepository: di.get<ProductsRepo>()),
  );

  di.registerFactory<DeliveryBloc>(
    () => DeliveryBloc(D_repository: di.get<DeliveryRepository>()),
  );

  di.registerFactory<BagBloc>(
    () => BagBloc(
      addItemUseCase: di<AddItemToBagUseCase>(),
      removeItemUseCase: di<RemoveItemFromBagUseCase>(),
      updateBagItemQuantityUseCase: di<UpdateBagItemQuantityUseCase>(),
      getBagUseCase: di<GetBagUseCase>(),
      clearBagUseCase: di<ClearBagUseCase>(),
      processPaymentUseCase: di<PayUseCase>(),
      deliveryBloc: di<DeliveryBloc>(),
    ),
  );

  di.registerFactory<ProfileBloc>(
    () => ProfileBloc(
      getUserProfile: di<GetUserProfileUseCase>(),
      updateProfile: di<UpdateProfileUseCase>(),
      uploadProfilePhoto: di<UploadProfilePhotoUseCase>(),
      changePassword: di<ChangePasswordUseCase>(),
      getUserOrders: di<GetUserOrdersUseCase>(),
      signOut: di<SignOutUseCase>(),
      getPaymentMethods: di<GetPaymentMethodsUseCase>(),
      savePaymentMethod: di<SavePaymentMethodUseCase>(),
      deletePaymentMethod: di<DeletePaymentMethodUseCase>(),
      setDefaultPaymentMethod: di<SetDefaultPaymentMethodUseCase>(),
    ),
  );
}
