import 'package:flutter/material.dart';
import '../models/new_listing_model.dart';
import 'new_listing_step3_page.dart';

class NewListingStep2Page extends StatefulWidget {
  final NewListing listing;

  const NewListingStep2Page({required this.listing, super.key});

  @override
  State<NewListingStep2Page> createState() => _NewListingStep2PageState();
}

class _NewListingStep2PageState extends State<NewListingStep2Page> {
  late TextEditingController locationController;

  @override
  void initState() {
    super.initState();
    locationController = TextEditingController(text: widget.listing.location);
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  void addImage() {
    // Mock: just add a demo image
    setState(() {
      widget.listing.images.add('assets/drill.jpg');
    });
  }

  void removeImage(int index) {
    setState(() {
      widget.listing.images.removeAt(index);
    });
  }

  void saveAndNext() {
    if (locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter location')),
      );
      return;
    }

    widget.listing.location = locationController.text;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewListingStep3Page(listing: widget.listing)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Listing', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
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
                _ProgressStep(number: 1, label: 'Info', isActive: false),
                Expanded(child: Container(height: 2, color: Colors.grey[300])),
                _ProgressStep(number: 2, label: 'Photos', isActive: true),
                Expanded(child: Container(height: 2, color: Colors.grey[300])),
                _ProgressStep(number: 3, label: 'Review', isActive: false),
              ],
            ),
            SizedBox(height: 32),

            // Photos Section
            Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),

            if (widget.listing.images.isEmpty)
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No photos yet', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: widget.listing.images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(widget.listing.images[index], fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => removeImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE8F5E9),
                  foregroundColor: Color(0xFF4CAF50),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Color(0xFF4CAF50)),
                  ),
                  elevation: 0,
                ),
                onPressed: addImage,
                icon: Icon(Icons.add_photo_alternate),
                label: Text('Add Photo'),
              ),
            ),

            SizedBox(height: 32),

            // Location Section
            Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                hintText: 'Enter location',
                prefixIcon: Icon(Icons.location_on, color: Color(0xFF4CAF50)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),

            SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Map preview', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),

            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: saveAndNext,
                    child: Text('Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
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
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF4CAF50) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
