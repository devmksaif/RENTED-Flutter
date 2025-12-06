import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/review_service.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      AppLogger.i('📖 Loading user reviews');
      final reviews = await _reviewService.getUserReviews();
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
        AppLogger.i('✅ Loaded ${reviews.length} user reviews');
      }
    } on ApiError catch (e) {
      AppLogger.e('Failed to load user reviews: ${e.message}', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
      }
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error loading user reviews', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'An unexpected error occurred',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _showEditReviewDialog(Map<String, dynamic> review) {
    final responsive = ResponsiveUtils(context);
    int selectedRating = review['rating'] as int? ?? 5;
    final commentController = TextEditingController(
      text: review['comment'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Edit Review',
            style: TextStyle(fontSize: responsive.fontSize(20)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating',
                  style: TextStyle(fontSize: responsive.fontSize(16)),
                ),
                SizedBox(height: responsive.spacing(8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: responsive.iconSize(32),
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                SizedBox(height: responsive.spacing(16)),
                TextField(
                  controller: commentController,
                  style: TextStyle(fontSize: responsive.fontSize(14)),
                  decoration: InputDecoration(
                    labelText: 'Comment (optional)',
                    labelStyle: TextStyle(fontSize: responsive.fontSize(14)),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  maxLength: 1000,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: responsive.fontSize(14)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _reviewService.updateReview(
                    reviewId: review['id'] as int,
                    rating: selectedRating,
                    comment: commentController.text.trim().isEmpty
                        ? null
                        : commentController.text.trim(),
                  );
                  if (mounted) {
                    Fluttertoast.showToast(
                      msg: 'Review updated successfully',
                      backgroundColor: Colors.green,
                    );
                    _loadReviews();
                  }
                } on ApiError catch (e) {
                  Fluttertoast.showToast(
                    msg: e.message,
                    backgroundColor: Colors.red,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Update',
                style: TextStyle(fontSize: responsive.fontSize(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteReviewDialog(Map<String, dynamic> review) {
    final responsive = ResponsiveUtils(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Review',
          style: TextStyle(fontSize: responsive.fontSize(20)),
        ),
        content: Text(
          'Are you sure you want to delete this review?',
          style: TextStyle(fontSize: responsive.fontSize(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: responsive.fontSize(14)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _reviewService.deleteReview(review['id'] as int);
                if (mounted) {
                  Fluttertoast.showToast(
                    msg: 'Review deleted successfully',
                    backgroundColor: Colors.green,
                  );
                  _loadReviews();
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
            child: Text(
              'Delete',
              style: TextStyle(fontSize: responsive.fontSize(14)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Reviews',
          style: TextStyle(fontSize: responsive.fontSize(20)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? Center(
                  child: Padding(
                    padding: responsive.responsivePadding(mobile: 24, tablet: 32, desktop: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.reviews_outlined,
                          size: responsive.iconSize(64),
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        Text(
                          'No reviews yet',
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
                  onRefresh: _loadReviews,
                  child: ListView.builder(
                    padding: responsive.responsivePadding(mobile: 16, tablet: 24, desktop: 32),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      final product = review['product'] ?? {};

                      return Card(
                        margin: EdgeInsets.only(bottom: responsive.spacing(12)),
                        child: ListTile(
                          leading: product['thumbnail_url'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product['thumbnail_url'],
                                    width: responsive.responsive(mobile: 60, tablet: 70, desktop: 80),
                                    height: responsive.responsive(mobile: 60, tablet: 70, desktop: 80),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: responsive.responsive(mobile: 60, tablet: 70, desktop: 80),
                                      height: responsive.responsive(mobile: 60, tablet: 70, desktop: 80),
                                      color: Colors.grey[200],
                                      child: Icon(Icons.image, size: responsive.iconSize(24)),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: responsive.responsive(mobile: 60, tablet: 70, desktop: 80),
                                  height: responsive.responsive(mobile: 60, tablet: 70, desktop: 80),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.inventory_2, size: responsive.iconSize(24)),
                                ),
                          title: Text(
                            product['title'] ?? 'Unknown Product',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: responsive.fontSize(16),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: responsive.spacing(4)),
                              Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (index) => Icon(
                                      index < (review['rating'] as int? ?? 0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: responsive.iconSize(16),
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                              if (review['comment'] != null) ...[
                                SizedBox(height: responsive.spacing(4)),
                                Text(
                                  review['comment'] ?? '',
                                  style: TextStyle(fontSize: responsive.fontSize(14)),
                                ),
                              ],
                              SizedBox(height: responsive.spacing(4)),
                              Text(
                                _formatDate(review['created_at']),
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12),
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: responsive.iconSize(24)),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: responsive.iconSize(18)),
                                    SizedBox(width: responsive.spacing(8)),
                                    Text(
                                      'Edit',
                                      style: TextStyle(fontSize: responsive.fontSize(14)),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: responsive.iconSize(18),
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: responsive.spacing(8)),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: responsive.fontSize(14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditReviewDialog(review);
                              } else if (value == 'delete') {
                                _showDeleteReviewDialog(review);
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/product-detail',
                              arguments: product['id'],
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

