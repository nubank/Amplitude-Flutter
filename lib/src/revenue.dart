class Revenue {
  Revenue() {
    payload[quantity] = 1;
  }

  final Map<String, dynamic> payload = {};

  static const event = 'revenue_amount';
  static const productId = r'$productId';
  static const price = r'$price';
  static const quantity = r'$quantity';
  static const revenueType = r'$revenueType';
  static const receipt = r'$receipt';

  bool isValid() => payload[price] != null;

  void setProductId(String productId) {
    payload[Revenue.productId] = productId;
  }

  void setPrice(double price) {
    payload[Revenue.price] = price;
  }

  void setQuantity(int quantity) {
    payload[Revenue.quantity] = quantity;
  }

  void setRevenueType(String revenueType) {
    payload[Revenue.revenueType] = revenueType;
  }

  void setProperties(Map<String, dynamic> properties) {
    payload.addAll(properties);
  }

  void setReceipt(String data) {
    payload[Revenue.receipt] = data;
  }
}
