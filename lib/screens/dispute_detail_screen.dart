import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/dispute_service.dart';
import '../models/api_error.dart';
import '../config/app_theme.dart';

class DisputeDetailScreen extends StatefulWidget {
  final int disputeId;

  const DisputeDetailScreen({super.key, required this.disputeId});

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  final DisputeService _disputeService = DisputeService();
  Map<String, dynamic>? _dispute;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDispute();
  }

  Future<void> _loadDispute() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dispute = await _disputeService.getDispute(widget.disputeId);
      if (mounted) {
        setState(() {
          _dispute = dispute;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
        Navigator.pop(context);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'investigating':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispute Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dispute == null
              ? const Center(child: Text('Dispute not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      Card(
                        color: _getStatusColor(
                          _dispute!['status'] ?? 'unknown',
                        ).withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: _getStatusColor(
                                  _dispute!['status'] ?? 'unknown',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (_dispute!['status'] ?? 'unknown')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(
                                          _dispute!['status'] ?? 'unknown',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Dispute Type
                      Text(
                        'Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          (_dispute!['dispute_type'] ?? 'other')
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                        ),
                        backgroundColor: AppTheme.primaryGreen.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_dispute!['description'] ?? ''),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Parties Involved
                      Text(
                        'Parties Involved',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_dispute!['reporter'] != null)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Reporter'),
                            subtitle: Text(
                              _dispute!['reporter']['name'] ?? 'Unknown',
                            ),
                          ),
                        ),
                      if (_dispute!['reported_user'] != null) ...[
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Reported User'),
                            subtitle: Text(
                              _dispute!['reported_user']['name'] ?? 'Unknown',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Resolution
                      if (_dispute!['resolution'] != null) ...[
                        Text(
                          'Resolution',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Card(
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_dispute!['resolution']),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Evidence
                      if (_dispute!['evidence'] != null &&
                          (_dispute!['evidence'] as List).isNotEmpty) ...[
                        Text(
                          'Evidence',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...(_dispute!['evidence'] as List).map((evidence) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.attachment),
                              title: const Text('Evidence File'),
                              subtitle: Text(evidence.toString()),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                      // Dates
                      Text(
                        'Timeline',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_dispute!['created_at'] != null)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Created'),
                            subtitle: Text(_formatDate(_dispute!['created_at'])),
                          ),
                        ),
                      if (_dispute!['updated_at'] != null) ...[
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.update),
                            title: const Text('Last Updated'),
                            subtitle: Text(_formatDate(_dispute!['updated_at'])),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

