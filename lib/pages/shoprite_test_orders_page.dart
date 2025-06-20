import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Add 'intl' package to your pubspec.yaml for date formatting
import 'package:ticketing_app/controllers/test_orders_controller.dart';
import 'package:ticketing_app/models/shoprite_order_model.dart';

class ShopriteTestOrdersPage extends GetView<TestOrdersController> {
  ShopriteTestOrdersPage({super.key});

  @override
  final controller = Get.put(TestOrdersController());

  @override
  Widget build(BuildContext context) {
    // Assuming the JSON structure has one primary order field to display
    var order = controller.shopriteOrders.first;
    final orderField = controller.shopriteOrders.first.orderField.first;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Obx(() {
        if (controller.isBusy.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.shopriteOrders.isEmpty) {
          return Center(child: Text("No orders found."));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderSummaryCard(orderField),
              const SizedBox(height: 20),
              _buildLineItemsSection(orderField.orderLineItemField),
              const SizedBox(height: 20),
              _buildDocumentHeaderExpansionTile(order.standardBusinessDocumentHeaderField),
            ],
          ),
        );
      }),
    );
  }

  // Card for the main order summary (Buyer, Seller, Date)
  Widget _buildOrderSummaryCard(OrderField orderField) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order: ${orderField.orderIdentificationField.entityIdentificationField}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const Divider(height: 24),
            _buildPartyInfo('Buyer', Icons.person_outline, orderField.buyerField),
            const SizedBox(height: 12),
            _buildPartyInfo('Seller', Icons.storefront_outlined, orderField.sellerField),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Created On', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text(
                  DateFormat.yMMMd().format(orderField.creationDateTimeField), // Formatted Date
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // A helper to display Buyer/Seller info consistently
  Widget _buildPartyInfo(String role, IconData icon, Party party) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey, size: 28),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(party.glnField, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // The main section for displaying all the line items in the order
  Widget _buildLineItemsSection(List<OrderLineItemField> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Line Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildLineItemExpansionTile(items[index]);
          },
        ),
      ],
    );
  }

  // The creative, expandable widget for each line item
  Widget _buildLineItemExpansionTile(OrderLineItemField item) {
    final tradeItem = item.transactionalTradeItemField;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Ensures the ExpansionTile ripple effect is contained
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Icon(Icons.shopping_basket_outlined, color: Colors.orange.shade800),
        ),
        title: Text(tradeItem.tradeItemDescriptionField.valueField, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('GTIN: ${tradeItem.gtinField}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Qty: ${item.requestedQuantityField.valueField.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          // This is the content shown when expanded
          Container(
            color: Colors.black.withOpacity(0.03),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDetailRow('Net Price:', '\$${item.netPriceField.valueField.toStringAsFixed(2)}'),
                _buildDetailRow('Net Amount:', '\$${item.netAmountField.valueField.toStringAsFixed(2)}'),
                const Divider(height: 20),
                if (item.orderLineItemDetailField.isNotEmpty)
                  _buildLogisticsInfo(item.orderLineItemDetailField.first.orderLogisticalInformationField),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for showing details within an expanded tile
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLogisticsInfo(OrderLogisticalInformationField logistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Shipping Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        _buildDetailRow('Ship To GLN:', logistics.shipToField.glnField),
        _buildDetailRow(
          'Delivery Date:',
          DateFormat.yMMMd().format(logistics.orderLogisticalDateInformationField.requestedDeliveryDateTimeField.dateField),
        ),
      ],
    );
  }

  // An expandable tile for less critical document header information
  Widget _buildDocumentHeaderExpansionTile(StandardBusinessDocumentHeader header) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.receipt_long_outlined, color: Colors.blueGrey),
        title: const Text('Document Header', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Tap to view metadata'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDetailRow('Header Version:', header.headerVersionField),
                _buildDetailRow('Standard:', header.documentIdentificationField.standardField),
                _buildDetailRow('Type Version:', header.documentIdentificationField.typeVersionField),
                const Divider(height: 20),
                _buildDetailRow('Sender EAN:', header.senderField.first.identifierField.valueField),
                _buildDetailRow('Receiver EAN:', header.receiverField.first.identifierField.valueField),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
