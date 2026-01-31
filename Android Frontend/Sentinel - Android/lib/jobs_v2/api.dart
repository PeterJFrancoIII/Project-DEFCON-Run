// Jobs v2 - API Client
// Clean HTTP client for Jobs v2 backend

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Jobs v2 API Response
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });
}

/// Jobs v2 API Client
class JobsApi {
  final String baseUrl;
  String? _token;

  JobsApi({required this.baseUrl});

  /// Set auth token
  void setToken(String? token) {
    _token = token;
  }

  /// Clear auth token
  void clearToken() {
    _token = null;
  }

  /// Build headers
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // =========================================================================
  // AUTH
  // =========================================================================

  /// Register new account (Strict)
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String phone, // E.164
    required String realNameFirst,
    required String realNameLast,
    required String role,
    String? organizationName, // Employer only
    String? organizationType, // Employer only
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'phone': phone,
        'real_name_first': realNameFirst,
        'real_name_last': realNameLast,
        'role': role,
        if (organizationName != null) 'organization_name': organizationName,
        if (organizationType != null) 'organization_type': organizationType,
      };

      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/auth/register'),
        headers: _headers,
        body: json.encode(body),
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Register error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Login
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
    Map<String, dynamic>? location, // {lat, lon, accuracy}
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        if (location != null) 'location': location,
      };

      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/auth/login'),
        headers: _headers,
        body: json.encode(body),
      );

      final data = json.decode(resp.body);
      if (resp.statusCode == 200 && data['token'] != null) {
        _token = data['token'];
      }
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Login error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Get profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/jobs_v2/auth/profile'),
        headers: _headers,
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data['profile'],
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Profile error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Update profile
  Future<ApiResponse<void>> updateProfile(Map<String, dynamic> updates) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/auth/profile/update'),
        headers: _headers,
        body: json.encode(updates),
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Update profile error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Upload profile photo (multipart)
  Future<ApiResponse<String>> uploadProfilePhoto(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse('$baseUrl/api/jobs_v2/auth/profile/photo');
      final request = http.MultipartRequest('POST', uri);

      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        imageBytes,
        filename: 'profile.jpg',
      ));

      final streamedResp = await request.send();
      final resp = await http.Response.fromStream(streamedResp);

      if (resp.statusCode != 200) {
        final data = json.decode(resp.body);
        return ApiResponse(
            success: false,
            error: data['error'] ?? 'Upload failed',
            statusCode: resp.statusCode);
      }

      final data = json.decode(resp.body);
      return ApiResponse(
        success: true,
        data: data['photo_url'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Upload photo error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Upgrade Worker to Employer
  Future<ApiResponse<Map<String, dynamic>>> upgradeToEmployer({
    required String organizationName,
    required String organizationType,
  }) async {
    try {
      final body = {
        'organization_name': organizationName,
        'organization_type': organizationType,
      };

      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/auth/upgrade_to_employer'),
        headers: _headers,
        body: json.encode(body),
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Upgrade to employer error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  // =========================================================================
  // LISTINGS
  // =========================================================================

  /// Create listing (Strict)
  Future<ApiResponse<Map<String, dynamic>>> createListing({
    required String category,
    required String payType, // cash | hourly | daily
    required Map<String, dynamic> payRange, // {min, max, currency}
    required String startTime,
    required String duration,
    required Map<String, dynamic> location, // {lat, lon}
    String? description,
  }) async {
    try {
      final body = {
        'category': category,
        'pay_type': payType,
        'pay_range': payRange,
        'start_time': startTime,
        'duration': duration,
        'location': location,
        'description': description ?? '',
      };

      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/listings/create'),
        headers: _headers,
        body: json.encode(body),
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Create listing error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Get single listing details
  Future<ApiResponse<Map<String, dynamic>>> getListing(String jobId) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/jobs_v2/listings/$jobId'),
        headers: _headers,
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data['listing'],
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Get listing error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Search listings (Lazy Load)
  Future<ApiResponse<List<dynamic>>> searchListings({
    String? category,
    double? lat,
    double? lon,
    int radiusKm = 50,
  }) async {
    try {
      final params = <String, String>{};
      if (category != null) params['category'] = category;
      if (lat != null) params['lat'] = lat.toString();
      if (lon != null) params['lon'] = lon.toString();
      params['radius_km'] = radiusKm.toString();

      final uri = Uri.parse('$baseUrl/api/jobs_v2/listings/search')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      final resp = await http.get(uri, headers: _headers);
      final data = json.decode(resp.body);

      return ApiResponse(
        success: resp.statusCode == 200,
        data: data['listings'],
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Search listings error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Get my listings (employer)
  Future<ApiResponse<List<dynamic>>> getMyListings() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/jobs_v2/listings/mine'),
        headers: _headers,
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data['listings'],
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] My listings error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Get applied jobs (worker)
  Future<ApiResponse<List<dynamic>>> getAppliedJobs() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/jobs_v2/listings/applied'),
        headers: _headers,
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data['applications'],
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Get applied jobs error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Apply to job (worker)
  Future<ApiResponse<Map<String, dynamic>>> applyToJob(String jobId,
      {String? message}) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/listings/$jobId/apply'),
        headers: _headers,
        body: json.encode({'message': message ?? ''}),
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Apply error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Get applicants for job (employer)
  Future<ApiResponse<List<dynamic>>> getApplicants(String jobId) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/jobs_v2/listings/$jobId/applicants'),
        headers: _headers,
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data['applicants'],
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Applicants error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Assign worker to job (employer)
  Future<ApiResponse<void>> assignWorker(String jobId, String workerId) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/listings/$jobId/assign'),
        headers: _headers,
        body: json.encode({'worker_id': workerId}),
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Assign error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Cancel listing (employer)
  Future<ApiResponse<void>> cancelListing(String jobId) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/listings/$jobId/cancel'),
        headers: _headers,
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Cancel listing error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Update listing (employer)
  /// Allowed fields: description, pay_range, duration, start_time
  Future<ApiResponse<void>> updateListing(
      String jobId, Map<String, dynamic> updates) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/listings/$jobId/update'),
        headers: _headers,
        body: json.encode(updates),
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Update listing error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  // =========================================================================
  // APPLICATIONS & MESSAGING
  // =========================================================================

  /// Get application details (worker or employer)
  Future<ApiResponse<Map<String, dynamic>>> getApplication(String appId) async {
    try {
      final url = Uri.parse('$baseUrl/api/jobs_v2/applications/$appId');
      debugPrint('[JobsApi] getApplication URL: $url');
      final resp = await http.get(
        url,
        headers: _headers,
      );

      if (resp.statusCode != 200) {
        debugPrint('[JobsApi] Error ${resp.statusCode}: ${resp.body}');
        return ApiResponse(
            success: false,
            error: 'Server Error (${resp.statusCode})',
            statusCode: resp.statusCode);
      }

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data['application'],
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Get app details error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Get messages for application
  Future<ApiResponse<List<dynamic>>> getMessages(String appId) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/jobs_v2/applications/$appId/messages'),
        headers: _headers,
      );

      if (resp.statusCode != 200) {
        return ApiResponse(
            success: false,
            error: 'Server Error (${resp.statusCode})',
            statusCode: resp.statusCode);
      }

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data['messages'],
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Get messages error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Mark messages as read
  Future<ApiResponse<void>> markMessagesRead(String appId) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/applications/$appId/messages/read'),
        headers: _headers,
      );

      if (resp.statusCode != 200) {
        return ApiResponse(
            success: false,
            error: 'Server Error (${resp.statusCode})',
            statusCode: resp.statusCode);
      }

      return ApiResponse(success: true, statusCode: resp.statusCode);
    } catch (e) {
      debugPrint('[JobsApi] Mark messages read error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Get global inbox conversations
  Future<ApiResponse<List<dynamic>>> getInbox() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/jobs_v2/inbox'),
        headers: _headers,
      );

      debugPrint('[JobsApi] getInbox STATUS: ${resp.statusCode}');

      if (resp.statusCode != 200) {
        debugPrint('[JobsApi] getInbox Error BODY: ${resp.body}');
        return ApiResponse(
            success: false,
            error: 'Server Error (${resp.statusCode})',
            statusCode: resp.statusCode);
      }

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data['conversations'],
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Get inbox error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Send message
  Future<ApiResponse<Map<String, dynamic>>> sendMessage(
      String appId, String content) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/applications/$appId/messages/send'),
        headers: _headers,
        body: json.encode({'content': content}),
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Send message error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Delete message (own messages only, within 2 min, unread)
  Future<ApiResponse<void>> deleteMessage(String messageId) async {
    try {
      final resp = await http.delete(
        Uri.parse('$baseUrl/api/jobs_v2/messages/$messageId/delete'),
        headers: _headers,
      );

      if (resp.statusCode != 200) {
        final data = json.decode(resp.body);
        return ApiResponse(
            success: false,
            error: data['error'] ?? 'Delete failed',
            statusCode: resp.statusCode);
      }

      return ApiResponse(success: true, statusCode: resp.statusCode);
    } catch (e) {
      debugPrint('[JobsApi] Delete message error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Upload a chat image
  Future<ApiResponse<Map<String, dynamic>>> uploadChatImage(
      Uint8List imageBytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/jobs_v2/messages/upload-image'),
      );
      request.headers.addAll(_headers);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'chat_image.jpg',
      ));

      final streamResp = await request.send();
      final resp = await http.Response.fromStream(streamResp);
      final data = json.decode(resp.body);

      return ApiResponse(
        success: resp.statusCode == 200,
        data: data,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Upload chat image error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Send message with image attachment
  Future<ApiResponse<Map<String, dynamic>>> sendMessageWithImage(
      String appId, String content, String imageUrl) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/applications/$appId/messages/send'),
        headers: _headers,
        body: json.encode({'content': content, 'image_url': imageUrl}),
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        data: data,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Send message with image error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Update application status (Employer Only: pending, accepted, declined)
  Future<ApiResponse<void>> updateApplicationStatus(
      String appId, String status) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/applications/$appId/status'),
        headers: _headers,
        body: json.encode({'status': status}),
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 200,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Update app status error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  /// Submit report (user or job)
  /// targetType: 'user' | 'job'
  /// reason: 'fraud' | 'spam' | 'harassment' | 'safety' | 'fake_listing' | 'other'
  Future<ApiResponse<void>> submitReport({
    required String targetId,
    required String targetType,
    required String reason,
    String? details,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/jobs_v2/report'),
        headers: _headers,
        body: json.encode({
          'target_id': targetId,
          'target_type': targetType,
          'reason': reason,
          'details': details ?? '',
        }),
      );

      final data = json.decode(resp.body);
      return ApiResponse(
        success: resp.statusCode == 201,
        error: data['error'],
        statusCode: resp.statusCode,
      );
    } catch (e) {
      debugPrint('[JobsApi] Report error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }
}
