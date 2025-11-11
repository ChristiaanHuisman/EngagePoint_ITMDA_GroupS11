import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class BusinessDashboardPage extends StatefulWidget {
  const BusinessDashboardPage({super.key});

  @override
  State<BusinessDashboardPage> createState() => _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends State<BusinessDashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final BusinessAnalyticsService _analyticsService = BusinessAnalyticsService();
  final String? _businessId = FirebaseAuth.instance.currentUser?.uid;

  String _selectedMetric = 'ViewsPerPost';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_businessId == null) {
      return const Scaffold(
        body: Center(child: Text("Error: Not logged in.")),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Business Dashboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.groups_outlined), text: 'Engagement'),
              Tab(icon: Icon(Icons.emoji_emotions_outlined), text: 'Sentiment'),
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
            ],
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildEngagementView(),
              _buildSentimentView(),
              _buildAnalyticsView(),
            ],
          ),
        ),
      ),
    );
  }

  // ENGAGEMENT TAB
  Widget _buildEngagementView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Engagement Analytics',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildStatCard(
            icon: Icons.people,
            label: 'Total Followers',
            stream: _firestoreService.getFollowerCount(_businessId!),
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.favorite,
            label: 'Total Likes on All Posts',
            future: _firestoreService.getTotalLikesForBusiness(_businessId),
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.reviews,
            label: 'Total Customer Reviews',
            future: _firestoreService.getTotalReviewsForBusiness(_businessId),
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentView() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final businessId = currentUser?.uid ?? '';
    final statsFuture = FirestoreService().getReviewSentimentStats(businessId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Sentiment Analysis',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, int>>(
            future: statsFuture,
            builder: (context, snapshot) {
              final stats =
                  snapshot.data ?? {'positive': 0, 'negative': 0, 'neutral': 0};

              return Column(
                children: [
                  _buildStatCard(
                    icon: Icons.thumb_up,
                    label: 'Positive Reviews',
                    future: Future.value(stats['positive']),
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.thumb_down,
                    label: 'Negative Reviews',
                    future: Future.value(stats['negative']),
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.remove,
                    label: 'Neutral Reviews',
                    future: Future.value(stats['neutral']),
                    color: Colors.grey,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required Color color,
    Stream<int>? stream,
    Future<int>? future,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 16)),
                  if (stream != null)
                    StreamBuilder<int>(
                      stream: stream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text('...');
                        return Text(snapshot.data.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold));
                      },
                    )
                  else if (future != null)
                    FutureBuilder<int>(
                      future: future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('...');
                        }
                        return Text(snapshot.data?.toString() ?? '0',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold));
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //PDF preview, used for download
  void _showPdfPreviewBottomSheet(BuildContext context, Uint8List pdfBytes) {
    debugPrint('Showing PDF preview bottom sheet.');
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: PdfPreview(
                build: (format) async => pdfBytes,
                canChangeOrientation: false,
                canChangePageFormat: false,
                allowPrinting: true,
                allowSharing: true,
                pdfFileName: 'AnalyticsReport.pdf',
              ),
            ),
          );
        },
      );
    },
  );
}


  // ANALYTICS TAB
  Widget _buildAnalyticsView() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _pickDate(context, true),
                child: Text('Start: ${dateFormat.format(_startDate)}'),
              ),
              TextButton(
                onPressed: () => _pickDate(context, false),
                child: Text('End: ${dateFormat.format(_endDate)}'),
              ),
            ],
          ),
          DropdownButton<String>(
            value: _selectedMetric,
            items: const [
              DropdownMenuItem(
                  value: 'ViewsPerPost', child: Text('Views per Post')),
              DropdownMenuItem(
                  value: 'VisitorsPerAccount',
                  child: Text('Visitors per Account')),
              DropdownMenuItem(
                  value: 'ClickThrough', child: Text('Click-Throughs')),
              DropdownMenuItem(
                  value: 'FollowsByDay', child: Text('Follows by Day')),
            ],
            onChanged: (v) => setState(() => _selectedMetric = v!),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchAnalyticsData,
            child: const Text('Show Data'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
  onPressed: () async {
    await _downloadPdf();
  },
  icon: const Icon(Icons.picture_as_pdf),
  label: const Text('Download PDF'),
),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              height: 300,
              child: _selectedMetric == 'ViewsPerPost'
                  ? _buildAnalyticsBarChart() // Show Bar Chart for Posts
                  : _buildAnalyticsLineChart(),
            ),
        ],
      ),
    );
  }

  //download the pdf
  Future<void> _downloadPdf() async {
  final start = DateFormat('yyyy-MM-dd').format(_startDate);
  final end = DateFormat('yyyy-MM-dd').format(_endDate);
  final id = _businessId!;
  Uint8List? pdfBytes;

  try {
    // Fetch and generate PDF data
    switch (_selectedMetric) {
      case 'ViewsPerPost':
        pdfBytes = await _analyticsService.downloadViewsPerPostPdf(id, start, end);
        break;
      case 'VisitorsPerAccount':
        pdfBytes = await _analyticsService.downloadVisitorsPerAccountPdf(id, start, end);
        break;
      case 'ClickThrough':
        pdfBytes = await _analyticsService.downloadClickThroughPdf(id, start, end);
        break;
      case 'FollowsByDay':
        pdfBytes = await _analyticsService.downloadFollowsByDayPdf(id, start, end);
        break;
    }
    debugPrint('PDF bytes length: ${pdfBytes?.length}');

    // If the widget was disposed while waiting for data, stop here
    if (!mounted) return;

    debugPrint('Preparing to show PDF preview.');

    if (pdfBytes == null || pdfBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to generate PDF.')),
      );
      return;
    }
    debugPrint('PDF generated with ${pdfBytes.length} bytes.');
    // Safely show the preview after checking context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showPdfPreviewBottomSheet(context, pdfBytes!);
      }
    });
  } catch (e) {
    if (!mounted) return;
    debugPrint('Error generating PDF: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to generate PDF: $e')),
    );
  }
}

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (newDate != null) {
      setState(() {
        if (isStart) {
          _startDate = newDate;
        } else {
          _endDate = newDate;
        }
      });
    }
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final start = DateFormat('yyyy-MM-dd').format(_startDate);
      final end = DateFormat('yyyy-MM-dd').format(_endDate);
      final id = _businessId!;

      debugPrint('Fetching $_selectedMetric for business $id');
      Map<String, dynamic>? result;
      switch (_selectedMetric) {
        case 'ViewsPerPost':
          result = await _analyticsService.getViewsPerPost(id, start, end);
          break;
        case 'VisitorsPerAccount':
          result =
              await _analyticsService.getVisitorsPerAccount(id, start, end);
          break;
        case 'ClickThrough':
          result = await _analyticsService.getClickThroughs(id, start, end);
          break;
        case 'FollowsByDay':
          result = await _analyticsService.getFollowsByDay(id, start, end);
          break;
      }

      setState(() => _analyticsData = result);
      debugPrint('Analytics data: $result');
    } catch (e) {
      debugPrint('Error fetching analytics data: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

 
  Widget _buildAnalyticsLineChart() {
    if (_analyticsData == null) {
      return const Center(
        child: Text('Press "Show Data" to load analytics.'),
      );
    }

    final dataPoints = (_analyticsData!['dataPoints'] ?? []) as List;
    if (dataPoints.isEmpty) {
      return const Center(child: Text('No data available for this range.'));
    }

    // Data Parsing Simplified for Line Charts
    final keyMap = {
      'VisitorsPerAccount': 'visitors',
      'ClickThrough': 'clicks',
      'FollowsByDay': 'follows',
    };
    final String dataKey = keyMap[_selectedMetric] ?? 'value';
    final String labelKey = 'date';

    final spots = <FlSpot>[];
    final bottomLabels = <int, String>{};
    double dataPeak = 0;

    for (int i = 0; i < dataPoints.length; i++) {
      final y = double.tryParse(dataPoints[i][dataKey]?.toString() ?? '0') ?? 0;

      if (y > dataPeak) {
        dataPeak = y; 
      }

      spots.add(FlSpot(i.toDouble(), y));

      final label = dataPoints[i][labelKey]?.toString() ?? '';
      if (label.isNotEmpty) {
        try {
          final dt = DateTime.parse(label);
          bottomLabels[i] = DateFormat('MMM d').format(dt);
        } catch (e) {
          bottomLabels[i] = label;
        }
      } else {
        bottomLabels[i] = label;
      }
    }


    //  Calculate new maxY with padding
    double newMaxY = 5; 
    if (dataPeak > 0) {
      double paddedPeak = dataPeak * 1.25; 

      if (paddedPeak <= 10) {
          newMaxY = paddedPeak.ceil().toDouble(); 
      } else if (paddedPeak <= 50) {
          newMaxY = (paddedPeak / 5).ceil() * 5;
      } else {
          newMaxY = (paddedPeak / 10).ceil() * 10;
      }
    }

    // Styling
    final primaryColor = Theme.of(context).colorScheme.primary;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: newMaxY,
        clipData: FlClipData.all(),
        // Interactive Tooltips
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot touchedSpot) {
              return Theme.of(context).colorScheme.primary;
            },
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                return LineTooltipItem(
                  '${bottomLabels[flSpot.x.toInt()] ?? ''}\n',
                  TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: flSpot.y.toStringAsFixed(0),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),

        // Cleaner Grid and Titles
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey,
              strokeWidth: 1,
            );
          },
        ),

        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if ((value % 1).abs() > 0.01) {
                  return const Text('');
                }

                String text;
                if (value >= 1000) {
                  text = NumberFormat.compact().format(value.toInt());
                } else {
                  text = value.toInt().toString();
                }

                return Text(
                  text,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.left,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final String text = bottomLabels[index] ?? '';

                if (dataPoints.length > 10 && index % 2 != 0) {
                  return const Text('');
                }

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  angle: -0.5,
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey, width: 1),
        ),

        // The Line and Gradient Fill
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor],
            ),
            barWidth: 4,
            isStrokeCapRound: true,          
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(
              show: true, 
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4, 
                  color: Colors.white, 
                  strokeWidth: 2, 
                  strokeColor: primaryColor, 
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsBarChart() {
    if (_analyticsData == null) {
      return const Center(
        child: Text('Press "Show Data" to load analytics.'),
      );
    }
    final dataPoints = (_analyticsData!['dataPoints'] ?? []) as List;
    if (dataPoints.isEmpty) {
      return const Center(child: Text('No data available for this range.'));
    }

    //  Data Parsing
    final String dataKey = 'views';
    final String labelKey = 'postName';
    final primaryColor = Theme.of(context).colorScheme.primary;

    final List<BarChartGroupData> barGroups = [];
    final Map<int, String> bottomLabels = {};

    for (int i = 0; i < dataPoints.length; i++) {
      final dataPoint = dataPoints[i];
      final y = double.tryParse(dataPoint[dataKey]?.toString() ?? '0') ?? 0;
      final label = dataPoint[labelKey]?.toString() ?? 'Post ${i + 1}';
      bottomLabels[i] = label;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: y,
              // Use a gradient for style
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            )
          ],
        ),
      );
    }

    // Chart Building
    return BarChart(
      BarChartData(
        // Tooltips
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) {
              return (Theme.of(context).colorScheme.primary);
            },
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${bottomLabels[group.x.toInt()] ?? ''}\n',
                TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: rod.toY.toStringAsFixed(0),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ),

        // Titles
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(),
                    style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final String text = bottomLabels[index] ?? '';

                if (dataPoints.length > 10 && index % 2 != 0) {
                  return const Text('');
                }

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  angle: -0.5,
                  child: Text(text,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600)),
                );
              },
            ),
          ),
        ),

        // Grid & Border
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey, width: 1),
        ),

        // --- 6. The Bars ---
        barGroups: barGroups,
        alignment: BarChartAlignment.spaceAround,
      ),
    );
  }
}
