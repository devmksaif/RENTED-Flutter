import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.responsivePadding(mobile: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Support Card
              Container(
                padding: EdgeInsets.all(responsive.spacing(20)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.support_agent, size: 60, color: Colors.white),
                    SizedBox(height: responsive.spacing(16)),
                    const Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(8)),
                    const Text(
                      'Our support team is here to help you',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(24)),

              // Quick Actions
              _buildSectionTitle('Quick Actions'),
              SizedBox(height: responsive.spacing(12)),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'Chat',
                      Icons.chat_bubble,
                      () {
                        Fluttertoast.showToast(
                          msg: 'Live chat coming soon',
                          backgroundColor: Colors.blue,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'Email',
                      Icons.email,
                      () {
                        Fluttertoast.showToast(
                          msg: 'Email: support@rented.com',
                          backgroundColor: Colors.green,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'Call',
                      Icons.phone,
                      () {
                        Fluttertoast.showToast(
                          msg: 'Call: 1-800-RENTED',
                          backgroundColor: Colors.green,
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(24)),

              // FAQ Section
              _buildSectionTitle('Frequently Asked Questions'),
              SizedBox(height: responsive.spacing(12)),
              _buildFAQCard(
                'How do I rent an item?',
                'Browse the catalog, select an item, choose your rental dates, and complete the booking.',
              ),
              SizedBox(height: responsive.spacing(12)),
              _buildFAQCard(
                'What payment methods are accepted?',
                'We accept all major credit cards, debit cards, and digital payment methods.',
              ),
              SizedBox(height: responsive.spacing(12)),
              _buildFAQCard(
                'How do I list my items?',
                'Go to your profile, tap "My Products", then tap the "+" button to add a new listing.',
              ),
              SizedBox(height: responsive.spacing(12)),
              _buildFAQCard(
                'What is the verification process?',
                'Upload your ID, selfie, and proof of address. Verification typically takes 1-3 business days.',
              ),
              SizedBox(height: responsive.spacing(12)),
              _buildFAQCard(
                'How do refunds work?',
                'Refunds are processed according to our cancellation policy. Full refunds for cancellations 24h+ before rental.',
              ),
              SizedBox(height: responsive.spacing(24)),

              // Support Categories
              _buildSectionTitle('Browse Help Topics'),
              SizedBox(height: responsive.spacing(12)),
              _buildTopicCard(context, 'Getting Started', Icons.rocket_launch),
              SizedBox(height: responsive.spacing(12)),
              _buildTopicCard(context, 'Account & Security', Icons.security),
              SizedBox(height: responsive.spacing(12)),
              _buildTopicCard(context, 'Payments & Billing', Icons.payment),
              SizedBox(height: responsive.spacing(12)),
              _buildTopicCard(context, 'Rental Process', Icons.handshake),
              SizedBox(height: responsive.spacing(12)),
              _buildTopicCard(context, 'Safety Guidelines', Icons.verified_user),
              SizedBox(height: responsive.spacing(24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryGreen),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Fluttertoast.showToast(
            msg: 'Help topic: $title',
            backgroundColor: Colors.blue,
          );
        },
      ),
    );
  }
}
