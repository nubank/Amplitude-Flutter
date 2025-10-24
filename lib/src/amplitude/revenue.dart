/// {@template revenue}
/// Class for building revenue event payloads for Amplitude Revenue API.
/// {@endtemplate}
final class Revenue {
  /// {@macro revenue}
  /// Creates a new Revenue instance with default quantity of 1.
  Revenue() {
    payload[quantity] = 1;
  }

  /// Payload map for the revenue event
  final Map<String, dynamic> payload = {};

  static const event = 'revenue_amount';
  static const productId = r'$productId';
  static const price = r'$price';
  static const quantity = r'$quantity';
  static const revenueType = r'$revenueType';
  static const receipt = r'$receipt';

  /// Validates if the revenue event has the required fields
  bool isValid() => payload[price] != null;

  /// Sets the product ID for the revenue event.
  void setProductId(String productId) {
    payload[Revenue.productId] = productId;
  }

  /// Sets the price for the revenue event.
  void setPrice(double price) {
    payload[Revenue.price] = price;
  }

  /// Sets the quantity for the revenue event.
  void setQuantity(int quantity) {
    payload[Revenue.quantity] = quantity;
  }

  /// Sets the revenue type for the revenue event.
  void setRevenueType(String revenueType) {
    payload[Revenue.revenueType] = revenueType;
  }

  /// Sets the properties for the revenue event.
  void setProperties(Map<String, dynamic> properties) {
    payload.addAll(properties);
  }

  /// Sets the receipt for the revenue event.
  void setReceipt(String data) {
    payload[Revenue.receipt] = data;
  }
}
