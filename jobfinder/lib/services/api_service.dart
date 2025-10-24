import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // For Android Emulator use 10.0.2.2
  // For iOS Simulator or Physical Device use your computer's IP
  // For Chrome/Web use localhost
  // For Production APK, replace with your production server URL
  static const String baseUrl = "http://localhost:8000/api";

  // Save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Clear token (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // Register user
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login(
    Map<String, dynamic> credentials,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(credentials),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['access_token']);
        return data;
      } else if (response.statusCode == 403) {
        // User not verified - return the detail object with status
        final error = jsonDecode(response.body);
        return {'status': 'unverified', 'detail': error['detail']};
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Verify code
  static Future<Map<String, dynamic>> verifyCode(
    int userId,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verify"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'code': code}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['access_token']);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Verification failed');
      }
    } catch (e) {
      throw Exception('Verification failed: $e');
    }
  }

  // Resend code
  static Future<Map<String, dynamic>> resendCode(int userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/resend-code"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to resend code');
      }
    } catch (e) {
      throw Exception('Failed to resend code: $e');
    }
  }

  // Get current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse("$baseUrl/users/me"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user info');
      }
    } catch (e) {
      throw Exception('Failed to get user info: $e');
    }
  }

  // Get user type from current user info
  static Future<String> getUserType() async {
    final userData = await getCurrentUser();
    return userData['user_type'] ?? 'employee';
  }

  // Get all jobs
  static Future<List<dynamic>> getJobs({
    int skip = 0,
    int limit = 20,
    String? category,
    String? search,
    String? jobType,
    int? minSalary,
    int? maxSalary,
    String? location,
  }) async {
    try {
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category,
        if (search != null) 'search': search,
        if (jobType != null) 'job_type': jobType,
        if (minSalary != null) 'min_salary': minSalary.toString(),
        if (maxSalary != null) 'max_salary': maxSalary.toString(),
        if (location != null) 'location': location,
      };

      final uri = Uri.parse(
        baseUrl + '/jobs',
      ).replace(queryParameters: queryParams);
      final token = await getToken();

      final response = await http.get(
        uri,
        headers:
            token != null
                ? {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                }
                : null,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load jobs');
      }
    } catch (e) {
      throw Exception('Failed to load jobs: $e');
    }
  }

  // Post a new job
  static Future<Map<String, dynamic>> postJob(
    Map<String, dynamic> jobData,
  ) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse("$baseUrl/jobs"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(jobData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to post job');
      }
    } catch (e) {
      throw Exception('Failed to post job: $e');
    }
  }

  // Apply for a job
  static Future<Map<String, dynamic>> applyForJob(
    int jobId,
    String message,
  ) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse("$baseUrl/applications"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'job_id': jobId, 'message': message}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to apply for job');
      }
    } catch (e) {
      throw Exception('Failed to apply for job: $e');
    }
  }

  // Logout
  static Future<void> logout() async {
    await clearToken();
  }
}
