import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/rental.dart';
import '../models/api_error.dart';
import '../services/rental_service.dart';
import '../services/dispute_service.dart';
import '../widgets/avatar_image.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

class RentalDetailScreen extends StatefulWidget {
  final int rentalId;

  const RentalDetailScreen({super.key, required this.rentalId});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  final RentalService _rentalService = RentalService();
  final DisputeService _disputeService = DisputeService();
  Rental? _rental;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRental();
  }

  Future<void> _loadRental() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all user rentals and find the one with matching ID
      final rentals = await _rentalService.getUserRentals();
      final rental = rentals.firstWhere(
        (r) => r.id == widget.rentalId,
        orElse: () => throw ApiError(
          message: 'Rental not found',
          statusCode: 404,
        ),
      );

      if (mounted) {
        setState(() {
          _rental = rental;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: e.message,
          backgroundColor: Colors.red,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Failed to load rental details',
          backgroundColor: Colors.red,
        );
        Navigator.pop(context);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Rental Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: responsive.fontSize(20),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: responsive.iconSize(24)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rental == null
              ? Center(
                  child: Text(
                    'Rental not found',
                    style: TextStyle(fontSize: responsive.fontSize(16)),
                  ),
                )
              : _buildRentalDetails(),
    );
  }

  Widget _buildRentalDetails() {
    final rental = _rental!;
    final theme = Theme.of(context);
    final responsive = ResponsiveUtils(context);
    return SingleChildScrollView(
      padding: responsive.responsivePadding(mobile: 16, tablet: 24, desktop: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(responsive.spacing(12)),
                    decoration: BoxDecoration(
                      color: _getStatusColor(rental.status).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(rental.status),
                      color: _getStatusColor(rental.status),
                      size: responsive.iconSize(24),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: theme.hintColor,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          rental.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: responsive.fontSize(18),
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(rental.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(16)),
            // Product Card
            Container(
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: responsive.responsive(mobile: 80, tablet: 100, desktop: 120),
                          height: responsive.responsive(mobile: 80, tablet: 100, desktop: 120),
                          color: theme.cardColor,
                          child: rental.product.thumbnail.isNotEmpty
                              ? Image.network(
                                  rental.product.thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_not_supported,
                                    color: theme.hintColor,
                                    size: responsive.iconSize(32),
                                  ),
                                )
                              : Icon(
                                  Icons.inventory_2,
                                  color: Colors.grey,
                                  size: responsive.iconSize(32),
                                ),
                        ),
                      ),
                      SizedBox(width: responsive.spacing(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rental.product.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: responsive.fontSize(16),
                              ),
                            ),
                            SizedBox(height: responsive.spacing(4)),
                            Text(
                              rental.product.category.name,
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: responsive.fontSize(14),
                              ),
                            ),
                            SizedBox(height: responsive.spacing(4)),
                            Text(
                              '\$${rental.product.pricePerDay}/day',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: responsive.fontSize(14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/product-detail',
                        arguments: rental.product.id,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, responsive.spacing(44)),
                    ),
                    child: Text(
                      'View Product Details',
                      style: TextStyle(fontSize: responsive.fontSize(14)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(16)),
            // Rental Information
            Container(
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rental Information',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  _buildInfoRow('Start Date', _formatDate(rental.startDate)),
                  Divider(height: responsive.spacing(24)),
                  _buildInfoRow('End Date', _formatDate(rental.endDate)),
                  Divider(height: responsive.spacing(24)),
                  _buildInfoRow(
                    'Total Price',
                    '\$${rental.totalPrice}',
                    valueStyle: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: responsive.fontSize(16),
                    ),
                  ),
                  if (rental.notes != null && rental.notes!.isNotEmpty) ...[
                    Divider(height: responsive.spacing(24)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: theme.hintColor,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          rental.notes!,
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(16)),
            // Renter Information
            Container(
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Renter',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  Row(
                    children: [
                      AvatarImage(
                        imageUrl: rental.renter.avatarUrl,
                        name: rental.renter.name,
                        radius: responsive.responsive(mobile: 30, tablet: 35, desktop: 40),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                      SizedBox(width: responsive.spacing(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rental.renter.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: responsive.fontSize(16),
                              ),
                            ),
                            SizedBox(height: responsive.spacing(4)),
                            Text(
                              rental.renter.email,
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: responsive.fontSize(14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(16)),
            // Dates
            Container(
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timeline',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  _buildInfoRow(
                    'Created',
                    _formatDateTime(rental.createdAt),
                  ),
                  Divider(height: responsive.spacing(24)),
                  _buildInfoRow(
                    'Last Updated',
                    _formatDateTime(rental.updatedAt),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(24)),
            // Create Dispute Button
            if (rental.status == 'completed' || rental.status == 'active')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCreateDisputeDialog(),
                  icon: Icon(Icons.gavel, size: responsive.iconSize(20)),
                  label: Text(
                    'Create Dispute',
                    style: TextStyle(fontSize: responsive.fontSize(14)),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: responsive.spacing(16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateDisputeDialog() {
    final rental = _rental!;
    String selectedType = 'damage';
    final descriptionController = TextEditingController();
    final evidenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Dispute'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dispute Type'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'damage', child: Text('Damage')),
                    DropdownMenuItem(
                      value: 'late_return',
                      child: Text('Late Return'),
                    ),
                    DropdownMenuItem(
                      value: 'not_as_described',
                      child: Text('Not As Described'),
                    ),
                    DropdownMenuItem(value: 'payment', child: Text('Payment')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value ?? 'damage';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                    hintText: 'Describe the issue...',
                  ),
                  maxLines: 4,
                  maxLength: 2000,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: evidenceController,
                  decoration: const InputDecoration(
                    labelText: 'Evidence URLs (comma-separated)',
                    border: OutlineInputBorder(),
                    hintText: 'https://example.com/image1.jpg, ...',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (descriptionController.text.trim().isEmpty) {
                  Fluttertoast.showToast(
                    msg: 'Description is required',
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                      final reportedAgainst = rental.product.owner?.id;
                      if (reportedAgainst == null) {
                        Fluttertoast.showToast(
                          msg: 'Unable to create dispute: Owner information missing',
                          backgroundColor: Colors.red,
                        );
                        return;
                      }
                  final evidence = evidenceController.text
                      .trim()
                      .split(',')
                      .where((url) => url.trim().isNotEmpty)
                      .map((url) => url.trim())
                      .toList();

                  await _disputeService.createDispute(
                    rentalId: rental.id,
                    reportedAgainst: reportedAgainst,
                    disputeType: selectedType,
                    description: descriptionController.text.trim(),
                    evidence: evidence.isEmpty ? null : evidence,
                  );

                  if (mounted) {
                    Fluttertoast.showToast(
                      msg: 'Dispute created successfully',
                      backgroundColor: Colors.green,
                    );
                    Navigator.pushNamed(context, '/disputes');
                  }
                } on ApiError catch (e) {
                  Fluttertoast.showToast(
                    msg: e.message,
                    backgroundColor: Colors.red,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Dispute'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    final responsive = ResponsiveUtils(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              TextStyle(
                fontSize: responsive.fontSize(14),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'active':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

