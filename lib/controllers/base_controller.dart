import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BaseController extends GetxController {
  final isBusy = false.obs;

  /// Copied this code from my Previous Project for times sake.
  /// However minor modifications where made to work for this project
  void showSnackBar(String message) {
    Get.snackbar('', message, backgroundColor: Colors.blue, colorText: Colors.white70);
  }
}
