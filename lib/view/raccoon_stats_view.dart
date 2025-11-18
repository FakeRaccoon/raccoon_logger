import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/raccoon_service.dart';

class RaccoonStatsView extends StatelessWidget {
  const RaccoonStatsView({super.key, required this.service});

  final RaccoonService service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          final calls = service.calls;

          if (calls.isEmpty) {
            return const Center(
              child: Text(
                'No data available',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final stats = _calculateStats(calls);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Cards
                _buildOverviewSection(stats),
                const SizedBox(height: 24),

                // Status Code Distribution
                _buildSectionTitle('Status Code Distribution'),
                const SizedBox(height: 8),
                _buildStatusCodeDistribution(stats),
                const SizedBox(height: 24),

                // HTTP Methods
                _buildSectionTitle('Requests by Method'),
                const SizedBox(height: 8),
                _buildMethodDistribution(stats),
                const SizedBox(height: 24),

                // Slowest Endpoints
                _buildSectionTitle('Top 5 Slowest Endpoints'),
                const SizedBox(height: 8),
                _buildSlowestEndpoints(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewSection(_Stats stats) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatCard(
          'Total Requests',
          stats.totalCalls.toString(),
          Icons.api,
          Colors.blue,
        ),
        _buildStatCard(
          'Success Rate',
          '${stats.successRate.toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Error Rate',
          '${stats.errorRate.toStringAsFixed(1)}%',
          Icons.error,
          Colors.red,
        ),
        _buildStatCard(
          'Avg Response',
          '${stats.avgResponseTime.toStringAsFixed(0)} ms',
          Icons.timer,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatusCodeDistribution(_Stats stats) {
    if (stats.statusCodeDistribution.isEmpty) {
      return const Text('No status codes available');
    }

    return Column(
      children: stats.statusCodeDistribution.entries.map((entry) {
        final percentage =
            (entry.value / stats.totalCalls * 100).toStringAsFixed(1);
        final color = _getStatusCodeColor(entry.key);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color),
                ),
                child: Text(
                  entry.key,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: entry.value / stats.totalCalls,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  '$percentage% (${entry.value})',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMethodDistribution(_Stats stats) {
    if (stats.methodDistribution.isEmpty) {
      return const Text('No methods available');
    }

    return Column(
      children: stats.methodDistribution.entries.map((entry) {
        final percentage =
            (entry.value / stats.totalCalls * 100).toStringAsFixed(1);
        final color = _getMethodColor(entry.key);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color),
                ),
                child: Text(
                  entry.key,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: entry.value / stats.totalCalls,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  '$percentage% (${entry.value})',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlowestEndpoints(_Stats stats) {
    if (stats.slowestEndpoints.isEmpty) {
      return const Text('No completed requests available');
    }

    return Column(
      children: stats.slowestEndpoints.map((call) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: _getMethodColor(call.method).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getMethodColor(call.method),
                ),
              ),
              child: Text(
                call.method,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: _getMethodColor(call.method),
                ),
              ),
            ),
            title: Text(
              call.endpoint,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              call.server,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${call.duration} ms',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusCodeColor(String statusCode) {
    final code = int.tryParse(statusCode) ?? 0;
    if (code >= 200 && code < 300) return Colors.green;
    if (code >= 300 && code < 400) return Colors.blue;
    if (code >= 400 && code < 500) return Colors.orange;
    if (code >= 500) return Colors.red;
    return Colors.grey;
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'PATCH':
        return Colors.purple;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  _Stats _calculateStats(List<RaccoonHttpCall> calls) {
    final totalCalls = calls.length;
    var successCount = 0;
    var errorCount = 0;
    var totalDuration = 0;
    final statusCodeDistribution = <String, int>{};
    final methodDistribution = <String, int>{};
    final completedCalls = <RaccoonHttpCall>[];

    for (final call in calls) {
      // Status codes
      final statusCode = call.response?.status;
      if (statusCode != null) {
        final status = statusCode.toString();
        statusCodeDistribution[status] = (statusCodeDistribution[status] ?? 0) + 1;

        // Success/Error counts
        if (statusCode >= 200 && statusCode < 300) {
          successCount++;
        } else if (statusCode >= 400) {
          errorCount++;
        }

        completedCalls.add(call);
      }

      if (call.error != null) {
        errorCount++;
      }

      // Methods
      methodDistribution[call.method] = (methodDistribution[call.method] ?? 0) + 1;

      // Duration
      totalDuration += call.duration;
    }

    // Sort slowest endpoints
    completedCalls.sort((a, b) => b.duration.compareTo(a.duration));
    final slowestEndpoints = completedCalls.take(5).toList();

    return _Stats(
      totalCalls: totalCalls,
      successRate: totalCalls > 0 ? (successCount / totalCalls) * 100 : 0,
      errorRate: totalCalls > 0 ? (errorCount / totalCalls) * 100 : 0,
      avgResponseTime: totalCalls > 0 ? totalDuration / totalCalls : 0,
      statusCodeDistribution: statusCodeDistribution,
      methodDistribution: methodDistribution,
      slowestEndpoints: slowestEndpoints,
    );
  }
}

class _Stats {
  final int totalCalls;
  final double successRate;
  final double errorRate;
  final double avgResponseTime;
  final Map<String, int> statusCodeDistribution;
  final Map<String, int> methodDistribution;
  final List<RaccoonHttpCall> slowestEndpoints;

  _Stats({
    required this.totalCalls,
    required this.successRate,
    required this.errorRate,
    required this.avgResponseTime,
    required this.statusCodeDistribution,
    required this.methodDistribution,
    required this.slowestEndpoints,
  });
}
