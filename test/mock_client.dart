import 'package:amplitude_flutter/amplitude_flutter.dart';

class MockClient implements Client {
  MockClient({this.httpStatus = 200});

  @override
  late String apiKey;
  int httpStatus;

  final List<dynamic> postCalls = <dynamic>[];

  @override
  Future<int> post(dynamic eventData) async {
    postCalls.add(eventData);
    return Future.value(httpStatus);
  }

  @override
  void postAsync(List<Map<String, dynamic>> eventData) {
    postCalls.add(eventData);
  }

  @override
  void dispose() {}

  void reset() => postCalls.clear();

  int get postCallCount => postCalls.length;
}
