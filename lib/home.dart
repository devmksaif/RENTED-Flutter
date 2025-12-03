import 'package:flutter/material.dart';
import 'pages/product_details_page.dart';
import 'pages/search_page.dart';
import 'pages/new_listing_step1_page.dart';
import 'pages/notifications_page.dart';
import 'pages/profile_page.dart';
import 'models/new_listing_model.dart';
import 'components/product_card.dart';
import 'data/mock_data.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: screenHeight * 0.5,
            floating: false,
            pinned: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/home.jpeg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Container(
                          color: Colors.green.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'RENTED',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4CAF50),
                                    letterSpacing: 1,
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 5),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NewListingStep1Page(listing: NewListing()),
                                  ),
                                );
                              },
                              child: Text('+  List Item'),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: Icon(Icons.notifications, color: Colors.grey, size: 28),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => NotificationsPage()),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.account_circle),
                              color: Color(0xFF4CAF50),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ProfilePage()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rent Anything You Need',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Access thousandss of items in your neighborhood',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Container(
                              width: 400,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'What are you looking for?',
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => SearchPage()),
                                      );
                                    },
                                    child: Text('Search'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Popular tags
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Popular:', style: TextStyle(color: Colors.white, fontSize: 16)),
                                const SizedBox(width: 12),
                                _PopularTag(text: 'Cameras'),
                                _PopularTag(text: 'Bikes'),
                                _PopularTag(text: 'Tools'),
                                _PopularTag(text: 'Furniture'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Scrollable listed items
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: mockProducts.map((product) {
                      return ProductCard(
                        product: product,
                        onViewDetails: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProductDetailsPage(product: product)),
                          );
                        },
                        onRent: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${product.title} added to cart!')),
                          );
                        },
                        onFavoriteChanged: (isFav) {
                          // Handle favorite
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularTag extends StatelessWidget {
  final String text;
  const _PopularTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
}
