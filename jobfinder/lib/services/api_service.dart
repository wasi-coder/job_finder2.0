import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data'; // Required for Web File Uploads (Uint8List)
import 'package:flutter/foundation.dart' show kIsWeb; // Required to check if running on Web

class ApiService {
  // For Android Emulator use 10.0.2.2
  // For iOS Simulator or Physical Device use your computer's IP
  // For Chrome/Web use localhost
  // For Production APK, replace with your production server URL
  static const String baseUrl = "http://localhost:8000/api";

  // ==================== AUTH TOKEN MANAGEMENT ====================

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // ==================== AUTHENTICATION ====================

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  static Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
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

  static Future<Map<String, dynamic>> verifyCode(int userId, String code) async {
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

  static Future<Map<String, dynamic>> resendCode(int userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/resend-code"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to resend code');
      }
    } catch (e) {
      throw Exception('Failed to resend code: $e');
    }
  }

  static Future<void> logout() async {
    await clearToken();
  }

  // ==================== USER DATA ====================

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

  static Future<String> getUserType() async {
    final userData = await getCurrentUser();
    return userData['user_type'] ?? 'employee';
  }

  // ==================== JOBS ====================

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

      final uri = Uri.parse('$baseUrl/jobs').replace(queryParameters: queryParams);
      final token = await getToken();

      final response = await http.get(
        uri,
        headers: token != null
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

  static Future<Map<String, dynamic>> postJob(Map<String, dynamic> jobData) async {
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

  // --- NEW: CLOSE JOB (For Employers) ---
  static Future<void> closeJob(int jobId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse("$baseUrl/jobs/$jobId/close"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to close job');
      }
    } catch (e) {
      throw Exception('Failed to close job: $e');
    }
  }

  // ==================== APPLICATIONS (APPLYING) ====================

  static Future<void> applyForJob({
    required int jobId,
    required String message,
    String? linkedin,
    String? github,
    String? portfolio,
    String? filePath,      // For Mobile App
    Uint8List? fileBytes,  // For Web App
    String? fileName,      // Required for Web App
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    var uri = Uri.parse("$baseUrl/applications");
    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    // Add Text Fields
    request.fields['job_id'] = jobId.toString();
    if (message.isNotEmpty) request.fields['message'] = message;
    if (linkedin != null) request.fields['linkedin'] = linkedin;
    if (github != null) request.fields['github'] = github;
    if (portfolio != null) request.fields['portfolio'] = portfolio;

    // Add File (Handle Web vs Mobile)
    if (kIsWeb && fileBytes != null) {
      // WEB: Use fromBytes
      request.files.add(http.MultipartFile.fromBytes(
        'cv', 
        fileBytes, 
        filename: fileName ?? 'cv.pdf'
      ));
    } else if (filePath != null) {
      // MOBILE: Use fromPath
      request.files.add(await http.MultipartFile.fromPath('cv', filePath));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to apply');
    }
  }

  // ==================== APPLICATION MANAGEMENT (VIEWING) ====================

  static Future<List<dynamic>> getMyApplications() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse("$baseUrl/applications/me"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load applications');
      }
    } catch (e) {
      throw Exception('Failed to load applications: $e');
    }
  }

  static Future<List<dynamic>> getEmployerApplications() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse("$baseUrl/employer/all-applications"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load applicants');
      }
    } catch (e) {
      throw Exception('Failed to load applicants: $e');
    }
  }

  // --- NEW: UPDATE APPLICATION STATUS (Shortlist, Hire, Reject) ---
  static Future<void> updateApplicationStatus(int applicationId, String status) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      // Note: We send status as a query parameter based on the backend implementation
      final uri = Uri.parse("$baseUrl/employer/applications/$applicationId?status=$status");
      
      final response = await http.put(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // ==================== MESSAGING (CHAT) ====================

  static Future<List<dynamic>> getMessages(int applicationId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse("$baseUrl/applications/$applicationId/messages"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  static Future<void> sendMessage({
    required int applicationId,
    required String content,
    String? filePath,      // For Mobile
    Uint8List? fileBytes,  // For Web
    String? fileName,      // For Web
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    var uri = Uri.parse("$baseUrl/messages");
    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['application_id'] = applicationId.toString();
    request.fields['content'] = content;

    // Handle File Upload (Web vs Mobile)
    if (kIsWeb && fileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        fileBytes, 
        filename: fileName ?? 'attachment'
      ));
    } else if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    }

    var streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200) {
      throw Exception('Failed to send message');
    }
  }
}