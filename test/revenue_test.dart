import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/amplitude_flutter.dart';

void main() {
  group('Revenue', () {
    late Revenue subject;

    setUp(() {
      subject = Revenue();
    });

    group('default constructor', () {
      test('sets a default revenue payload', () {
        expect(subject.payload, equals(<String, dynamic>{r'$quantity': 1}));
      });
    });

    group('property setters', () {
      test('sets the price', () {
        subject.setPrice(12.23);
        subject.setQuantity(12);
        subject.setProductId('product');
        subject.setProperties(<String, String>{'key': 'value'});
        subject.setRevenueType('cash');
        expect(
            subject.payload,
            equals(<String, dynamic>{
              r'$price': 12.23,
              r'$quantity': 12,
              r'$productId': 'product',
              r'$revenueType': 'cash',
              'key': 'value'
            }));
      });
    });

    group('isValid', () {
      test('requires price to be present', () {
        expect(subject.isValid(), equals(false));
        subject.setPrice(12.23);
        expect(subject.isValid(), equals(true));
      });
    });
  });
}
