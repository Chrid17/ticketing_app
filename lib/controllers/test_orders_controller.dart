import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'base_controller.dart';
import '../models/shoprite_order_model.dart';

class TestOrdersController extends BaseController {
  get ordersList => <ShopriteOrder>[];
  // A reactive list to hold the Shoprite orders.
  // Using .obs makes it observable, so UI widgets can update automatically.
  var shopriteOrders = <ShopriteOrder>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      isBusy(true); // Set loading to true

      // 1. Read the JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/shoprite_test_order.json');

      // 2. Decode the JSON string into a Map
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      // 3. Parse the JSON map into a ShopriteOrder object using your model
      final ShopriteOrder order = ShopriteOrder.fromJson(jsonMap);

      shopriteOrders.add(order);

    } catch (e) {
      // Handle any errors during file loading or parsing
      // Get.snackbar("Error", "Failed to load orders: $e");
      // print("Error loading orders: $e");
    } finally {
      isBusy(false); // Set loading to false when done
    }
  }
}
