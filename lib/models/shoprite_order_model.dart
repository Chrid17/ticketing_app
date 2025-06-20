import 'dart:convert';

ShopriteOrder shopriteOrderFromJson(String str) => ShopriteOrder.fromJson(json.decode(str));

String shopriteOrderToJson(ShopriteOrder data) => json.encode(data.toJson());

class ShopriteOrder {
  StandardBusinessDocumentHeader standardBusinessDocumentHeaderField;
  List<OrderField> orderField;

  ShopriteOrder({required this.standardBusinessDocumentHeaderField, required this.orderField});

  factory ShopriteOrder.fromJson(Map<String, dynamic> json) => ShopriteOrder(
    standardBusinessDocumentHeaderField: StandardBusinessDocumentHeader.fromJson(json["standardBusinessDocumentHeaderField"]),
    orderField: List<OrderField>.from(json["orderField"].map((x) => OrderField.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "standardBusinessDocumentHeaderField": standardBusinessDocumentHeaderField.toJson(),
    "orderField": List<dynamic>.from(orderField.map((x) => x.toJson())),
  };
}

class OrderField {
  OrderIdentificationField orderIdentificationField;
  OrderTypeCodeField orderTypeCodeField;
  Party buyerField;
  Party sellerField;
  List<OrderLineItemField> orderLineItemField;
  DateTime creationDateTimeField;
  int documentStatusCodeField;

  OrderField({
    required this.orderIdentificationField,
    required this.orderTypeCodeField,
    required this.buyerField,
    required this.sellerField,
    required this.orderLineItemField,
    required this.creationDateTimeField,
    required this.documentStatusCodeField,
  });

  factory OrderField.fromJson(Map<String, dynamic> json) => OrderField(
    orderIdentificationField: OrderIdentificationField.fromJson(json["orderIdentificationField"]),
    orderTypeCodeField: OrderTypeCodeField.fromJson(json["orderTypeCodeField"]),
    buyerField: Party.fromJson(json["buyerField"]),
    sellerField: Party.fromJson(json["sellerField"]),
    orderLineItemField: List<OrderLineItemField>.from(json["orderLineItemField"].map((x) => OrderLineItemField.fromJson(x))),
    creationDateTimeField: DateTime.parse(json["creationDateTimeField"]),
    documentStatusCodeField: json["documentStatusCodeField"],
  );

  Map<String, dynamic> toJson() => {
    "orderIdentificationField": orderIdentificationField.toJson(),
    "orderTypeCodeField": orderTypeCodeField.toJson(),
    "buyerField": buyerField.toJson(),
    "sellerField": sellerField.toJson(),
    "orderLineItemField": List<dynamic>.from(orderLineItemField.map((x) => x.toJson())),
    "creationDateTimeField": creationDateTimeField.toIso8601String(),
    "documentStatusCodeField": documentStatusCodeField,
  };
}

class Party {
  String glnField;
  List<AdditionalPartyIdentificationField> additionalPartyIdentificationField;

  Party({required this.glnField, required this.additionalPartyIdentificationField});

  factory Party.fromJson(Map<String, dynamic> json) => Party(
    glnField: json["glnField"],
    additionalPartyIdentificationField: List<AdditionalPartyIdentificationField>.from(
      json["additionalPartyIdentificationField"].map((x) => AdditionalPartyIdentificationField.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "glnField": glnField,
    "additionalPartyIdentificationField": List<dynamic>.from(additionalPartyIdentificationField.map((x) => x.toJson())),
  };
}

class AdditionalPartyIdentificationField {
  String additionalPartyIdentificationTypeCodeField;
  String valueField;

  AdditionalPartyIdentificationField({required this.additionalPartyIdentificationTypeCodeField, required this.valueField});

  factory AdditionalPartyIdentificationField.fromJson(Map<String, dynamic> json) => AdditionalPartyIdentificationField(
    additionalPartyIdentificationTypeCodeField: json["additionalPartyIdentificationTypeCodeField"] ?? 'null',
    valueField: json["valueField"] ?? 'null',
  );

  Map<String, dynamic> toJson() => {
    "additionalPartyIdentificationTypeCodeField": additionalPartyIdentificationTypeCodeField,
    "valueField": valueField,
  };
}

class OrderIdentificationField {
  String entityIdentificationField;
  ContentOwnerField contentOwnerField;

  OrderIdentificationField({required this.entityIdentificationField, required this.contentOwnerField});

  factory OrderIdentificationField.fromJson(Map<String, dynamic> json) => OrderIdentificationField(
    entityIdentificationField: json["entityIdentificationField"],
    contentOwnerField: ContentOwnerField.fromJson(json["contentOwnerField"]),
  );

  Map<String, dynamic> toJson() => {
    "entityIdentificationField": entityIdentificationField,
    "contentOwnerField": contentOwnerField.toJson(),
  };
}

class ContentOwnerField {
  List<AdditionalPartyIdentificationField> additionalPartyIdentificationField;

  ContentOwnerField({required this.additionalPartyIdentificationField});

  factory ContentOwnerField.fromJson(Map<String, dynamic> json) => ContentOwnerField(
    additionalPartyIdentificationField: List<AdditionalPartyIdentificationField>.from(
      json["additionalPartyIdentificationField"].map((x) => AdditionalPartyIdentificationField.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "additionalPartyIdentificationField": List<dynamic>.from(additionalPartyIdentificationField.map((x) => x.toJson())),
  };
}

class OrderLineItemField {
  String lineItemNumberField;
  MonetaryAmountField requestedQuantityField;
  MonetaryAmountField netAmountField;
  MonetaryAmountField netPriceField;
  TransactionalTradeItemField transactionalTradeItemField;
  List<OrderLineItemDetailField> orderLineItemDetailField;

  OrderLineItemField({
    required this.lineItemNumberField,
    required this.requestedQuantityField,
    required this.netAmountField,
    required this.netPriceField,
    required this.transactionalTradeItemField,
    required this.orderLineItemDetailField,
  });

  factory OrderLineItemField.fromJson(Map<String, dynamic> json) => OrderLineItemField(
    lineItemNumberField: json["lineItemNumberField"],
    requestedQuantityField: MonetaryAmountField.fromJson(json["requestedQuantityField"]),
    netAmountField: MonetaryAmountField.fromJson(json["netAmountField"]),
    netPriceField: MonetaryAmountField.fromJson(json["netPriceField"]),
    transactionalTradeItemField: TransactionalTradeItemField.fromJson(json["transactionalTradeItemField"]),
    orderLineItemDetailField: List<OrderLineItemDetailField>.from(
      json["orderLineItemDetailField"].map((x) => OrderLineItemDetailField.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "lineItemNumberField": lineItemNumberField,
    "requestedQuantityField": requestedQuantityField.toJson(),
    "netAmountField": netAmountField.toJson(),
    "netPriceField": netPriceField.toJson(),
    "transactionalTradeItemField": transactionalTradeItemField.toJson(),
    "orderLineItemDetailField": List<dynamic>.from(orderLineItemDetailField.map((x) => x.toJson())),
  };
}

class MonetaryAmountField {
  double valueField;

  MonetaryAmountField({required this.valueField});

  factory MonetaryAmountField.fromJson(Map<String, dynamic> json) =>
      MonetaryAmountField(valueField: json["valueField"]?.toDouble());

  Map<String, dynamic> toJson() => {"valueField": valueField};
}

class OrderLineItemDetailField {
  MonetaryAmountField requestedQuantityField;
  OrderLogisticalInformationField orderLogisticalInformationField;

  OrderLineItemDetailField({required this.requestedQuantityField, required this.orderLogisticalInformationField});

  factory OrderLineItemDetailField.fromJson(Map<String, dynamic> json) => OrderLineItemDetailField(
    requestedQuantityField: MonetaryAmountField.fromJson(json["requestedQuantityField"]),
    orderLogisticalInformationField: OrderLogisticalInformationField.fromJson(json["orderLogisticalInformationField"]),
  );

  Map<String, dynamic> toJson() => {
    "requestedQuantityField": requestedQuantityField.toJson(),
    "orderLogisticalInformationField": orderLogisticalInformationField.toJson(),
  };
}

class OrderLogisticalInformationField {
  Party shipToField;
  OrderLogisticalDateInformationField orderLogisticalDateInformationField;

  OrderLogisticalInformationField({required this.shipToField, required this.orderLogisticalDateInformationField});

  factory OrderLogisticalInformationField.fromJson(Map<String, dynamic> json) => OrderLogisticalInformationField(
    shipToField: Party.fromJson(json["shipToField"]),
    orderLogisticalDateInformationField: OrderLogisticalDateInformationField.fromJson(
      json["orderLogisticalDateInformationField"],
    ),
  );

  Map<String, dynamic> toJson() => {
    "shipToField": shipToField.toJson(),
    "orderLogisticalDateInformationField": orderLogisticalDateInformationField.toJson(),
  };
}

class OrderLogisticalDateInformationField {
  RequestedDeliveryDateTimeField requestedDeliveryDateTimeField;

  OrderLogisticalDateInformationField({required this.requestedDeliveryDateTimeField});

  factory OrderLogisticalDateInformationField.fromJson(Map<String, dynamic> json) => OrderLogisticalDateInformationField(
    requestedDeliveryDateTimeField: RequestedDeliveryDateTimeField.fromJson(json["requestedDeliveryDateTimeField"]),
  );

  Map<String, dynamic> toJson() => {"requestedDeliveryDateTimeField": requestedDeliveryDateTimeField.toJson()};
}

class RequestedDeliveryDateTimeField {
  DateTime dateField;

  RequestedDeliveryDateTimeField({required this.dateField});

  factory RequestedDeliveryDateTimeField.fromJson(Map<String, dynamic> json) =>
      RequestedDeliveryDateTimeField(dateField: DateTime.parse(json["dateField"]));

  Map<String, dynamic> toJson() => {"dateField": dateField.toIso8601String()};
}

class TransactionalTradeItemField {
  TradeItemDescriptionField tradeItemDescriptionField;
  String gtinField;
  List<AdditionalPartyIdentificationField> additionalTradeItemIdentificationField;

  TransactionalTradeItemField({
    required this.tradeItemDescriptionField,
    required this.gtinField,
    required this.additionalTradeItemIdentificationField,
  });

  factory TransactionalTradeItemField.fromJson(Map<String, dynamic> json) => TransactionalTradeItemField(
    tradeItemDescriptionField: TradeItemDescriptionField.fromJson(json["tradeItemDescriptionField"]),
    gtinField: json["gtinField"],
    additionalTradeItemIdentificationField: List<AdditionalPartyIdentificationField>.from(
      json["additionalTradeItemIdentificationField"].map((x) => AdditionalPartyIdentificationField.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "tradeItemDescriptionField": tradeItemDescriptionField.toJson(),
    "gtinField": gtinField,
    "additionalTradeItemIdentificationField": List<dynamic>.from(additionalTradeItemIdentificationField.map((x) => x.toJson())),
  };
}

class TradeItemDescriptionField {
  String valueField;

  TradeItemDescriptionField({required this.valueField});

  factory TradeItemDescriptionField.fromJson(Map<String, dynamic> json) =>
      TradeItemDescriptionField(valueField: json["valueField"]);

  Map<String, dynamic> toJson() => {"valueField": valueField};
}

class OrderTypeCodeField {
  String codeListVersionField;
  String valueField;

  OrderTypeCodeField({required this.codeListVersionField, required this.valueField});

  factory OrderTypeCodeField.fromJson(Map<String, dynamic> json) =>
      OrderTypeCodeField(codeListVersionField: json["codeListVersionField"], valueField: json["valueField"]);

  Map<String, dynamic> toJson() => {"codeListVersionField": codeListVersionField, "valueField": valueField};
}

class StandardBusinessDocumentHeader {
  String headerVersionField;
  List<ReceiverField> senderField;
  List<ReceiverField> receiverField;
  DocumentIdentificationField documentIdentificationField;
  ManifestField manifestField;

  StandardBusinessDocumentHeader({
    required this.headerVersionField,
    required this.senderField,
    required this.receiverField,
    required this.documentIdentificationField,
    required this.manifestField,
  });

  factory StandardBusinessDocumentHeader.fromJson(Map<String, dynamic> json) => StandardBusinessDocumentHeader(
    headerVersionField: json["headerVersionField"],
    senderField: List<ReceiverField>.from(json["senderField"].map((x) => ReceiverField.fromJson(x))),
    receiverField: List<ReceiverField>.from(json["receiverField"].map((x) => ReceiverField.fromJson(x))),
    documentIdentificationField: DocumentIdentificationField.fromJson(json["documentIdentificationField"]),
    manifestField: ManifestField.fromJson(json["manifestField"]),
  );

  Map<String, dynamic> toJson() => {
    "headerVersionField": headerVersionField,
    "senderField": List<dynamic>.from(senderField.map((x) => x.toJson())),
    "receiverField": List<dynamic>.from(receiverField.map((x) => x.toJson())),
    "documentIdentificationField": documentIdentificationField.toJson(),
    "manifestField": manifestField.toJson(),
  };
}

class DocumentIdentificationField {
  String standardField;
  String typeVersionField;
  String instanceIdentifierField;
  String typeField;
  bool multipleTypeField;
  DateTime creationDateAndTimeField;

  DocumentIdentificationField({
    required this.standardField,
    required this.typeVersionField,
    required this.instanceIdentifierField,
    required this.typeField,
    required this.multipleTypeField,
    required this.creationDateAndTimeField,
  });

  factory DocumentIdentificationField.fromJson(Map<String, dynamic> json) => DocumentIdentificationField(
    standardField: json["standardField"],
    typeVersionField: json["typeVersionField"],
    instanceIdentifierField: json["instanceIdentifierField"],
    typeField: json["typeField"],
    multipleTypeField: json["multipleTypeField"],
    creationDateAndTimeField: DateTime.parse(json["creationDateAndTimeField"]),
  );

  Map<String, dynamic> toJson() => {
    "standardField": standardField,
    "typeVersionField": typeVersionField,
    "instanceIdentifierField": instanceIdentifierField,
    "typeField": typeField,
    "multipleTypeField": multipleTypeField,
    "creationDateAndTimeField": creationDateAndTimeField.toIso8601String(),
  };
}

class ManifestField {
  String numberOfItemsField;

  ManifestField({required this.numberOfItemsField});

  factory ManifestField.fromJson(Map<String, dynamic> json) => ManifestField(numberOfItemsField: json["numberOfItemsField"]);

  Map<String, dynamic> toJson() => {"numberOfItemsField": numberOfItemsField};
}

class ReceiverField {
  IdentifierField identifierField;

  ReceiverField({required this.identifierField});

  factory ReceiverField.fromJson(Map<String, dynamic> json) =>
      ReceiverField(identifierField: IdentifierField.fromJson(json["identifierField"]));

  Map<String, dynamic> toJson() => {"identifierField": identifierField.toJson()};
}

class IdentifierField {
  String authorityField;
  String valueField;

  IdentifierField({required this.authorityField, required this.valueField});

  factory IdentifierField.fromJson(Map<String, dynamic> json) =>
      IdentifierField(authorityField: json["authorityField"], valueField: json["valueField"]);

  Map<String, dynamic> toJson() => {"authorityField": authorityField, "valueField": valueField};
}
