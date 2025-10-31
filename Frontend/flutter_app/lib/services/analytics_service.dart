import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class BusinessAnalyticsService {
  static const String _baseUrl =
      'https://business-analytics-570976278139.us-central1.run.app/';

  //Json fetches for visual diagrams
  Future<Map<String, dynamic>?> getViewsPerPost(
      String businessId, String startDate, String endDate) async {
    final url =
        Uri.parse('$_baseUrl/api/Analytics/ViewsPerPost/$businessId/$startDate/$endDate');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Future<Map<String, dynamic>?> getVisitorsPerAccount(
      String businessId, String startDate, String endDate) async {
    final url =
        Uri.parse('$_baseUrl/api/Analytics/VisitorsPerAccount/$businessId/$startDate/$endDate');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Future<Map<String, dynamic>?> getClickThroughs(
      String businessId, String startDate, String endDate) async {
    final url =
        Uri.parse('$_baseUrl/api/Analytics/ClickThrough/$businessId/$startDate/$endDate');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Future<Map<String, dynamic>?> getFollowsByDay(
      String businessId, String startDate, String endDate) async {
    final url =
        Uri.parse('$_baseUrl/api/Analytics/FollowsByDay/$businessId/$startDate/$endDate');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }
//pdf generation
Future<Uint8List> generatePdfBytes(
      String title,
      String businessId,
      String startDate,
      String endDate,
      List<Map<String, dynamic>> dataPoints) async {
    final pdf = pw.Document();
    final dateRange = '$startDate to $endDate';
    final dateFormat = DateFormat('MMM d, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Business ID: $businessId'),
          pw.Text('Date Range: $dateRange'),
          pw.Text('Generated on: $dateFormat'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: dataPoints.isNotEmpty
                ? dataPoints.first.keys.toList()
                : ['No Data'],
            data: dataPoints
                .map((e) => e.values.map((v) => v.toString()).toList())
                .toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }
//PDF download functions
Future<Uint8List> downloadViewsPerPostPdf(
    String businessId, String startDate, String endDate) async {
  final json = await getViewsPerPost(businessId, startDate, endDate);
  final dataPoints = (json?['dataPoints'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  return generatePdfBytes('Views Per Post Report', businessId, startDate, endDate, dataPoints);
}

Future<Uint8List> downloadVisitorsPerAccountPdf(
    String businessId, String startDate, String endDate) async {
  final json = await getVisitorsPerAccount(businessId, startDate, endDate);
  final dataPoints = (json?['dataPoints'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  return generatePdfBytes('Views Per Post Report', businessId, startDate, endDate, dataPoints);
}

Future<Uint8List> downloadClickThroughPdf(
    String businessId, String startDate, String endDate) async {
  final json = await getClickThroughs(businessId, startDate, endDate);
  final dataPoints = (json?['dataPoints'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  return generatePdfBytes('Views Per Post Report', businessId, startDate, endDate, dataPoints);
}

Future<Uint8List> downloadFollowsByDayPdf(
    String businessId, String startDate, String endDate) async {
 final json = await getFollowsByDay(businessId, startDate, endDate);
  final dataPoints = (json?['dataPoints'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  return generatePdfBytes('Views Per Post Report', businessId, startDate, endDate, dataPoints);
}
}