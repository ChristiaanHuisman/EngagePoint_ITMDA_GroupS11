import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';

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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Engagement'),
              Tab(icon: Icon(Icons.emoji_emotions_outlined), text: 'Sentiment'),
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
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

  // SENTIMENT TAB
  Widget _buildSentimentView() {
    return FutureBuilder<Map<String, int>>(
      // Use function from FirestoreService
      future: _firestoreService.getReviewSentimentStats(_businessId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Could not load sentiment data.'));
        }

        final sentimentData = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review Sentiment Analysis',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildStatCard(
                icon: Icons.thumb_up,
                label: 'Positive Reviews',
                future: Future.value(sentimentData['positive'] ?? 0),
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.thumb_down,
                label: 'Negative Reviews',
                future: Future.value(sentimentData['negative'] ?? 0),
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.remove,
                label: 'Neutral Reviews',
                future: Future.value(sentimentData['neutral'] ?? 0),
                color: Colors.grey,
              ),
            ],
          ),
        );
      },
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
            onPressed: _downloadPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Download PDF'),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(height: 300, child: _buildAnalyticsChart()),
        ],
      ),
    );
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

  Future<void> _downloadPdf() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final start = DateFormat('yyyy-MM-dd').format(_startDate);
    final end = DateFormat('yyyy-MM-dd').format(_endDate);
    final id = _businessId!;

    try {
      await _analyticsService.downloadReportPdf(
          _selectedMetric, id, start, end);

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('PDF download started.')),
      );
    } catch (e) {
      debugPrint('Error downloading PDF: $e');

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to download PDF: $e')),
      );
    }
  }

  Widget _buildAnalyticsChart() {
    if (_analyticsData == null) {
      return const Center(child: Text('No data yet.'));
    }

    final dataPoints = (_analyticsData!['dataPoints'] ?? []) as List;
    if (dataPoints.isEmpty) {
      return const Center(child: Text('No data available for this range.'));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final y = double.tryParse(dataPoints[i]['views']?.toString() ??
              dataPoints[i]['visitors']?.toString() ??
              dataPoints[i]['follows']?.toString() ??
              '0') ??
          0;
      spots.add(FlSpot(i.toDouble(), y));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dataPoints.length) {
                  return Text(
                    dataPoints[index]['date']?.toString() ??
                        dataPoints[index]['postName']?.toString() ??
                        '',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            spots: spots,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
