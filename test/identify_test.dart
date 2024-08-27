import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/amplitude_flutter.dart';

void main() {
  group('Identify', () {
    Identify? subject;

    setUp(() {
      subject = Identify();
    });

    group('default constructor', () {
      test('sets a blank identify payload', () {
        expect(subject!.payload, equals(<String, dynamic>{}));
      });
    });

    group('adding user property operations', () {
      test(r'.set adds $set operations', () {
        subject!.set('cohort', 'Test A');
        expect(
            subject!.payload,
            equals(
              {
                r'$set': {'cohort': 'Test A'}
              },
            ));
      });

      test(r'.setOnce adds $setOnce operations', () {
        subject!.setOnce('cohort', 'Test A');
        expect(
            subject!.payload,
            equals(
              {
                r'$setOnce': {'cohort': 'Test A'}
              },
            ));
      });

      test(r'.add adds $add operations', () {
        subject!.add('login_count', 1);
        expect(
            subject!.payload,
            equals(
              {
                r'$add': {'login_count': 1}
              },
            ));
      });

      test(r'.append adds $append operations', () {
        subject!.append('tags', 'new tag');
        expect(
            subject!.payload,
            equals(
              {
                r'$append': {'tags': 'new tag'}
              },
            ));
      });

      test(r'.unset adds $unset operations', () {
        subject!.unset('demo_user');
        expect(
            subject!.payload,
            equals(
              {
                r'$unset': {'demo_user': '-'}
              },
            ));
      });

      test('combining multiple operations', () {
        subject
          ..set('cohort', 'Test A')
          ..setOnce('completed_onboarding', 'true')
          ..add('login_count', 1)
          ..append('tags', 'new tag')
          ..unset('demo_user');

        expect(
            subject!.payload,
            equals(
              {
                r'$set': {'cohort': 'Test A'},
                r'$setOnce': {'completed_onboarding': 'true'},
                r'$add': {'login_count': 1},
                r'$unset': {'demo_user': '-'},
                r'$append': {'tags': 'new tag'},
              },
            ));
      });
    });

    group('.addOp', () {
      const String op = r'$set';

      test(r'adds an user property operation', () {
        subject!.addOp(op, 'cohort', 'Test A');
        expect(subject!.payload, containsPair(op, {'cohort': 'Test A'}));
      });

      test(r'adds multiple properties for an operation', () {
        subject
          ..addOp(op, 'cohort', 'Test A')
          ..addOp(op, 'interests', ['chess', 'football']);

        expect(
            subject!.payload,
            containsPair(op, {
              'cohort': 'Test A',
              'interests': ['chess', 'football']
            }));
      });

      test(r'overwrites entries with the same key for a given operation', () {
        subject..addOp(op, 'cohort', 'Test A')..addOp(op, 'cohort', 'Test B');

        expect(subject!.payload, containsPair(op, {'cohort': 'Test B'}));
      });
    });
  });
}
