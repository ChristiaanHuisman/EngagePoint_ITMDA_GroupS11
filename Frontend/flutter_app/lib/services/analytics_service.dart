import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Connects the Flutter app to the Google Cloud Run-hosted Business Analytics API.
class BusinessAnalyticsService {
  // Base URL of your deployed Cloud Run API
  static const String _baseUrl =
      'https://business-analytics-570976278139.us-central1.run.app/';

  // Fetches total views per post for a business.
  Future<Map<String, dynamic>?> getViewsPerPost(
      String businessId, String startDate, String endDate) async {
    final url =
        Uri.parse('$_baseUrl/api/Analytics/ViewsPerPost/$businessId/$startDate/$endDate');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error fetching ViewsPerPost: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception in getViewsPerPost: $e');
    }
    return null;
  }

  // Fetches unique visitors per account for a business.
  Future<Map<String, dynamic>?> getVisitorsPerAccount(
      String businessId, String startDate, String endDate) async {
    final url =
        Uri.parse('$_baseUrl/api/Analytics/VisitorsPerAccount/$businessId/$startDate/$endDate');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error fetching VisitorsPerAccount: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception in getVisitorsPerAccount: $e');
    }
    return null;
  }

  // Fetches click-throughs per day for a business.
  Future<Map<String, dynamic>?> getClickThroughs(
      String businessId, String startDate, String endDate) async {
    final url =
        Uri.parse('$_baseUrl/api/Analytics/ClickThrough/$businessId/$startDate/$endDate');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error fetching ClickThroughs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception in getClickThroughs: $e');
    }
    return null;
  }

  // Fetches follows per day for a business.
  Future<Map<String, dynamic>?> getFollowsByDay(
      String businessId, String startDate, String endDate) async {
    final url =
        Uri.parse('$_baseUrl/api/Analytics/FollowsByDay/$businessId/$startDate/$endDate');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error fetching FollowsByDay: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception in getFollowsByDay: $e');
    }
    return null;
  }

  // Downloads a PDF report from the given endpoint.
  Future<http.Response> downloadReportPdf(String reportType, String businessId,
      String startDate, String endDate) async {
    final url =
        Uri.parse('$_baseUrl/api/Analytics/$reportType/$businessId/$startDate/$endDate/pdf');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to download $reportType report PDF');
    }
  }
}