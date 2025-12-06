import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/dispute_service.dart';
import '../models/api_error.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

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
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dispute Details',
          style: TextStyle(fontSize: responsive.fontSize(20)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dispute == null
              ? Center(
                  child: Text(
                    'Dispute not found',
                    style: TextStyle(fontSize: responsive.fontSize(16)),
                  ),
                )
              : SingleChildScrollView(
                  padding: responsive.responsivePadding(mobile: 16, tablet: 24, desktop: 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Card
                        Card(
                          color: _getStatusColor(
                            _dispute!['status'] ?? 'unknown',
                          ).withValues(alpha: 0.1),
                          child: Padding(
                            padding: EdgeInsets.all(responsive.spacing(16)),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: _getStatusColor(
                                    _dispute!['status'] ?? 'unknown',
                                  ),
                                  size: responsive.iconSize(24),
                                ),
                                SizedBox(width: responsive.spacing(12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(12),
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: responsive.spacing(4)),
                                      Text(
                                        (_dispute!['status'] ?? 'unknown')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(16),
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
                        SizedBox(height: responsive.spacing(16)),
                        // Dispute Type
                        Text(
                          'Type',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: responsive.fontSize(18),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        Chip(
                          label: Text(
                            (_dispute!['dispute_type'] ?? 'other')
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: TextStyle(fontSize: responsive.fontSize(12)),
                          ),
                          backgroundColor: AppTheme.primaryGreen.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        // Description
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: responsive.fontSize(18),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(responsive.spacing(16)),
                            child: Text(
                              _dispute!['description'] ?? '',
                              style: TextStyle(fontSize: responsive.fontSize(14)),
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        // Parties Involved
                        Text(
                          'Parties Involved',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: responsive.fontSize(18),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        if (_dispute!['reporter'] != null)
                          Card(
                            child: ListTile(
                              leading: Icon(Icons.person, size: responsive.iconSize(24)),
                              title: Text(
                                'Reporter',
                                style: TextStyle(fontSize: responsive.fontSize(16)),
                              ),
                              subtitle: Text(
                                _dispute!['reporter']['name'] ?? 'Unknown',
                                style: TextStyle(fontSize: responsive.fontSize(14)),
                              ),
                            ),
                          ),
                        if (_dispute!['reported_user'] != null) ...[
                          SizedBox(height: responsive.spacing(8)),
                          Card(
                            child: ListTile(
                              leading: Icon(Icons.person_outline, size: responsive.iconSize(24)),
                              title: Text(
                                'Reported User',
                                style: TextStyle(fontSize: responsive.fontSize(16)),
                              ),
                              subtitle: Text(
                                _dispute!['reported_user']['name'] ?? 'Unknown',
                                style: TextStyle(fontSize: responsive.fontSize(14)),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: responsive.spacing(16)),
                        // Resolution
                        if (_dispute!['resolution'] != null) ...[
                          Text(
                            'Resolution',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: responsive.fontSize(18),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(8)),
                          Card(
                            color: Colors.green[50],
                            child: Padding(
                              padding: EdgeInsets.all(responsive.spacing(16)),
                              child: Text(
                                _dispute!['resolution'],
                                style: TextStyle(fontSize: responsive.fontSize(14)),
                              ),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(16)),
                        ],
                        // Evidence
                        if (_dispute!['evidence'] != null &&
                            (_dispute!['evidence'] as List).isNotEmpty) ...[
                          Text(
                            'Evidence',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: responsive.fontSize(18),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(8)),
                          ...(_dispute!['evidence'] as List).map((evidence) {
                            return Card(
                              margin: EdgeInsets.only(bottom: responsive.spacing(8)),
                              child: ListTile(
                                leading: Icon(Icons.attachment, size: responsive.iconSize(24)),
                                title: Text(
                                  'Evidence File',
                                  style: TextStyle(fontSize: responsive.fontSize(16)),
                                ),
                                subtitle: Text(
                                  evidence.toString(),
                                  style: TextStyle(fontSize: responsive.fontSize(14)),
                                ),
                                trailing: Icon(Icons.chevron_right, size: responsive.iconSize(24)),
                              ),
                            );
                          }),
                        ],
                        SizedBox(height: responsive.spacing(16)),
                        // Dates
                        Text(
                          'Timeline',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: responsive.fontSize(18),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        if (_dispute!['created_at'] != null)
                          Card(
                            child: ListTile(
                              leading: Icon(Icons.calendar_today, size: responsive.iconSize(24)),
                              title: Text(
                                'Created',
                                style: TextStyle(fontSize: responsive.fontSize(16)),
                              ),
                              subtitle: Text(
                                _formatDate(_dispute!['created_at']),
                                style: TextStyle(fontSize: responsive.fontSize(14)),
                              ),
                            ),
                          ),
                        if (_dispute!['updated_at'] != null) ...[
                          SizedBox(height: responsive.spacing(8)),
                          Card(
                            child: ListTile(
                              leading: Icon(Icons.update, size: responsive.iconSize(24)),
                              title: Text(
                                'Last Updated',
                                style: TextStyle(fontSize: responsive.fontSize(16)),
                              ),
                              subtitle: Text(
                                _formatDate(_dispute!['updated_at']),
                                style: TextStyle(fontSize: responsive.fontSize(14)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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

