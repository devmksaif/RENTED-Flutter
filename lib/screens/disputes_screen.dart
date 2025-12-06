import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/dispute_service.dart';
import '../models/api_error.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  final DisputeService _disputeService = DisputeService();
  List<Map<String, dynamic>> _disputes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final disputes = await _disputeService.getDisputes();
      if (mounted) {
        setState(() {
          _disputes = disputes;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
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
          'Disputes',
          style: TextStyle(fontSize: responsive.fontSize(20)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: responsive.iconSize(24)),
            onPressed: () {
              // Navigate to create dispute screen
              Fluttertoast.showToast(
                msg: 'Create dispute feature coming soon',
                backgroundColor: Colors.blue,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _disputes.isEmpty
              ? Center(
                  child: Padding(
                    padding: responsive.responsivePadding(mobile: 24, tablet: 32, desktop: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.gavel_outlined,
                          size: responsive.iconSize(64),
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        Text(
                          'No disputes yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: responsive.fontSize(18),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDisputes,
                  child: ListView.builder(
                    itemCount: _disputes.length,
                    itemBuilder: (context, index) {
                      final dispute = _disputes[index];
                      final status = dispute['status'] ?? 'unknown';
                      final disputeType = dispute['dispute_type'] ?? 'other';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(status),
                            child: const Icon(
                              Icons.gavel,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            disputeType.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                dispute['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (dispute['created_at'] != null)
                                    Text(
                                      _formatDate(dispute['created_at']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/dispute-detail',
                              arguments: dispute['id'],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

