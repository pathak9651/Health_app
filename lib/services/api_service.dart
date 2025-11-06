import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:health_app/models/user.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<http.Response> reportSymptoms(Map<String, dynamic> data) {
    return http.post(
      Uri.parse('$baseUrl/report/symptom'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> reportWater(Map<String, dynamic> data) {
    return http.post(
      Uri.parse('$baseUrl/report/water'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> registerUser(String phone, String name, String role) {
    return http.post(
      Uri.parse('$baseUrl/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'phone': phone, 'name': name, 'role': role}),
    );
  }

  static Future<http.Response> sendOtp(String phone) {
    return http.post(
      Uri.parse('$baseUrl/send-otp'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'phone': phone}),
    );
  }

  static Future<http.Response> verifyOtp(String phone, String otp) {
    return http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
  }

  static Future<http.Response> loginUser(String phone) {
    return http.post(
      Uri.parse('$baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'phone': phone}),
    );
  }

  static Future<List<dynamic>> fetchAlerts() async {
    final response = await http.get(Uri.parse('$baseUrl/alerts'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load alerts');
    }
  }

  static Future<Map<String, dynamic>> fetchUnseenAlertsCount() async {
    final response = await http.get(Uri.parse('$baseUrl/alerts/unseen_count'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load unseen alerts count');
    }
  }

  static Future<List<dynamic>> fetchSymptomReports() async {
    final response = await http.get(Uri.parse('$baseUrl/symptom-reports'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load symptom reports');
    }
  }

  static Future<List<dynamic>> fetchWaterReports() async {
    final response = await http.get(Uri.parse('$baseUrl/water-reports'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load water reports');
    }
  }

  static Future<http.Response> updateUser(int userId, String name, String role) {
    return http.put(
      Uri.parse('$baseUrl/user/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'name': name, 'role': role}),
    );
  }

  static Future<Map<String, dynamic>> predictOutbreak(String village) async {
    final response = await http.get(Uri.parse('$baseUrl/predict-outbreak?village=$village'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get prediction');
    }
  }

  static Future<Map<String, dynamic>> sendChatbotMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chatbot'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send message');
    }
  }
}
