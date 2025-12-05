import 'package:flutter/material.dart';
import '../models/new_listing_model.dart';
import '../config/app_theme.dart';
import 'new_listing_step2_page.dart';

class NewListingStep1Page extends StatefulWidget {
  final NewListing listing;

  const NewListingStep1Page({required this.listing, super.key});

  @override
  State<NewListingStep1Page> createState() => _NewListingStep1PageState();
}

class _NewListingStep1PageState extends State<NewListingStep1Page> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;

  final List<String> categories = [
    'Electronics',
    'Tools & Equipment',
    'Sports & Outdoors',
    'Home & Garden',
    'Other',
  ];
  final List<String> conditions = ['Like New', 'Good', 'Fair', 'For Parts'];
  final List<String> priceTypes = ['per day', 'per week', 'per month'];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.listing.title);
    descriptionController = TextEditingController(
      text: widget.listing.description,
    );
    priceController = TextEditingController(
      text: widget.listing.price > 0 ? '${widget.listing.price}' : '',
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void saveAndNext() {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        priceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    widget.listing.title = titleController.text;
    widget.listing.description = descriptionController.text;
    widget.listing.price = double.tryParse(priceController.text) ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewListingStep2Page(listing: widget.listing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'New Listing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            Row(
              children: [
                _ProgressStep(number: 1, label: 'Info', isActive: true),
                Expanded(child: Container(height: 2, color: theme.dividerColor)),
                _ProgressStep(number: 2, label: 'Photos', isActive: false),
                Expanded(child: Container(height: 2, color: theme.dividerColor)),
                _ProgressStep(number: 3, label: 'Review', isActive: false),
              ],
            ),
            SizedBox(height: 32),

            // Title
            Text(
              'Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'What are you renting?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Category
            Text(
              'Category',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField(
              initialValue: widget.listing.category.isEmpty
                  ? categories[0]
                  : widget.listing.category,
              onChanged: (value) {
                setState(() => widget.listing.category = value ?? '');
              },
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Description
            Text(
              'Description',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the condition and features...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Price
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField(
                        initialValue: widget.listing.priceType,
                        onChanged: (value) {
                          setState(
                            () => widget.listing.priceType = value ?? 'per day',
                          );
                        },
                        items: priceTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type, maxLines: 1),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Condition
            Text(
              'Condition',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField(
              initialValue: widget.listing.condition,
              onChanged: (value) {
                setState(() => widget.listing.condition = value ?? 'Like New');
              },
              items: conditions.map((cond) {
                return DropdownMenuItem(value: cond, child: Text(cond));
              }).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            SizedBox(height: 32),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: saveAndNext,
                child: Text(
                  'Next: Photos & Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;

  const _ProgressStep({
    required this.number,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryGreen : theme.dividerColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: isActive ? Colors.white : theme.hintColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
