import 'package:ulmo_ecmmerce/core/models/catagory.dart';
import 'package:ulmo_ecmmerce/features/categories/data/repo/category_repo_impl.dart';

class FetchCategoriesUseCase{
  final CategoriesRepo categoriesRepo;
  FetchCategoriesUseCase(this.categoriesRepo);
  Future<List<Category>> call() async{
    return await categoriesRepo.fetchMainCategories();
  }
}