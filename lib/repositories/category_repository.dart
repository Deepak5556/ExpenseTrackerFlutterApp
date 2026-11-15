import '../models/category_model.dart';

abstract interface class CategoryRepository {
  Future<List<CategoryModel>> readCategories();
  Future<void> saveCategories(List<CategoryModel> categories);
}
