import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/purchase.dart';
import '../models/api_error.dart';
import '../services/purchase_service.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

class MyPurchasesScreen extends StatefulWidget {
  const MyPurchasesScreen({super.key});

  @override
  State<MyPurchasesScreen> createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends State<MyPurchasesScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  List<Purchase> _purchases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final purchases = await _purchaseService.getUserPurchases();
      if (mounted) {
        setState(() {
          _purchases = purchases;
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

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Purchases',
          style: TextStyle(fontSize: responsive.fontSize(20)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _purchases.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadPurchases,
              child: ListView.builder(
                padding: responsive.responsivePadding(mobile: 16, tablet: 24, desktop: 32),
                itemCount: _purchases.length,
                itemBuilder: (context, index) {
                  final purchase = _purchases[index];
                  return _buildPurchaseCard(purchase);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final responsive = ResponsiveUtils(context);
    return Center(
      child: Padding(
        padding: responsive.responsivePadding(mobile: 24, tablet: 32, desktop: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: responsive.iconSize(64),
              color: Colors.grey[400],
            ),
            SizedBox(height: responsive.spacing(16)),
            Text(
              'No purchases yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: responsive.fontSize(22),
              ),
            ),
            SizedBox(height: responsive.spacing(8)),
            Text(
              'Browse products to start buying',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: responsive.fontSize(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseCard(Purchase purchase) {
    Color statusColor;
    IconData statusIcon;

    switch (purchase.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'completed':
        statusColor = AppTheme.primaryGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: purchase.product.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: purchase.product.thumbnail.isNotEmpty
                      ? Image.network(
                          purchase.product.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Icons.inventory_2, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.product.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          purchase.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${purchase.purchasePrice}',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      purchase.createdAt.toIso8601String().split('T')[0],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
