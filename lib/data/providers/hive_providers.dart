import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/business_config.dart';
import '../../core/constants/app_constants.dart';

final productsBoxProvider = Provider<Box<Product>>((ref) {
  return Hive.box<Product>(AppConstants.productsBox);
});

final salesBoxProvider = Provider<Box<Sale>>((ref) {
  return Hive.box<Sale>(AppConstants.salesBox);
});

final settingsBoxProvider = Provider<Box<BusinessConfig>>((ref) {
  return Hive.box<BusinessConfig>(AppConstants.settingsBox);
});

final expensesBoxProvider = Provider<Box<Expense>>((ref) {
  return Hive.box<Expense>(AppConstants.expensesBox);
});

final mainCashBoxProvider = Provider<Box<double>>((ref) {
  return Hive.box<double>(AppConstants.mainCashBox);
});
