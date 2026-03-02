// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Uses compile-time variables. 
  // Run with: flutter run --dart-define=API_URL=https://your-production-url.com
  final String _baseUrl = const String.fromEnvironment(
    'API_URL', 
    defaultValue: 'http://192.168.240.1:8000'
  );

  Future<Map<String, dynamic>> fetchRates() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/api/v1/rates"));

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON.
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        // If the server did not return a 200 OK response,
        // throw an exception that the UI can catch.
        throw Exception('Failed to load rates. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Catch any other exceptions (e.g., network errors)
      throw Exception('Failed to connect to the server: $e');
    }
  }
}
