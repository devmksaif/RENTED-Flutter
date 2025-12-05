import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/responsive_utils.dart';
import '../services/image_picker_service.dart';
import '../services/verification_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final VerificationService _verificationService = VerificationService();
  bool _isLoading = false;
  bool _isLoadingStatus = true;
  File? _idFrontFile;
  File? _idBackFile;
  File? _selfieFile;
  String _documentType = 'national_id';
  Map<String, dynamic>? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() {
      _isLoadingStatus = true;
    });

    try {
      final status = await _verificationService.getVerificationStatus();
      if (mounted) {
        setState(() {
          _verificationStatus = status;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    // Show loading indicator while checking status
    if (_isLoadingStatus) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Account Verification',
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If already verified, show success screen
    if (_verificationStatus != null &&
        _verificationStatus!['status'] == 'verified') {
      return _buildVerifiedScreen(context);
    }

    // If pending, show pending screen
    // Check both status == 'pending' OR document_status == 'pending' OR has_submitted_documents == true
    final status = _verificationStatus?['status'];
    final documentStatus = _verificationStatus?['document_status'];
    final hasSubmittedDocuments = _verificationStatus?['has_submitted_documents'] == true;
    
    if (_verificationStatus != null &&
        (status == 'pending' || 
         documentStatus == 'pending' || 
         hasSubmittedDocuments)) {
      return _buildPendingScreen(context);
    }

    // If rejected, show rejection screen with option to resubmit
    if (_verificationStatus != null &&
        _verificationStatus!['status'] == 'rejected') {
      return _buildRejectedScreen(context, responsive);
    }

    // Default: Show upload form (only if no documents have been submitted)
    return _buildUploadForm(context, responsive);
  }

  Widget _buildVerifiedScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Account Verification',
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  size: 80,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Account Verified!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your account has been successfully verified.\nYou can now list products for rent and sale.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingScreen(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Account Verification',
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pending_actions,
                  size: 80,
                  color: Color(0xFFFFA726),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verification Pending',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your verification documents are being reviewed.\nThis usually takes 1-3 business days.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              if (_verificationStatus != null &&
                  _verificationStatus!['submitted_at'] != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Submitted: ${_formatDate(_verificationStatus!['submitted_at'])}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: const Color(0xFFFFA726),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildRejectedScreen(
    BuildContext context,
    ResponsiveUtils responsive,
  ) {
    final adminNotes = _verificationStatus?['admin_notes'] as String?;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Account Verification',
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
      body: SingleChildScrollView(
        padding: responsive.responsivePadding(mobile: 16),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel, size: 80, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verification Rejected',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (adminNotes != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason for Rejection:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      adminNotes,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Your verification was rejected.\nPlease resubmit with valid documents.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _verificationStatus = null; // Reset to show upload form
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Resubmit Documents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadForm(BuildContext context, ResponsiveUtils responsive) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Account Verification',
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        size: 48,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Get Verified',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Verified accounts can list products for rent and sale',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Requirements
              const Text(
                'Requirements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildRequirementTile(
                icon: Icons.badge_outlined,
                title: 'Government ID',
                subtitle: 'Valid government-issued identification',
              ),
              _buildRequirementTile(
                icon: Icons.face_outlined,
                title: 'Selfie',
                subtitle: 'Clear photo of yourself holding your ID',
              ),
              _buildRequirementTile(
                icon: Icons.home_outlined,
                title: 'Proof of Address',
                subtitle: 'Utility bill or bank statement (last 3 months)',
              ),
              const SizedBox(height: 32),
              // Upload Section
              const Text(
                'Upload Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildUploadCard(
                title: 'Government ID (Front)',
                icon: Icons.credit_card,
                imagePath: _idFrontFile?.path,
                onTap: () => _pickImage('idFront'),
              ),
              const SizedBox(height: 12),
              _buildUploadCard(
                title: 'Government ID (Back)',
                icon: Icons.credit_card,
                imagePath: _idBackFile?.path,
                onTap: () => _pickImage('idBack'),
              ),
              const SizedBox(height: 12),
              _buildUploadCard(
                title: 'Selfie with ID',
                icon: Icons.face,
                imagePath: _selfieFile?.path,
                onTap: () => _pickImage('selfie'),
              ),
              const SizedBox(height: 16),
              // Document type selector
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.document_scanner,
                    color: Color(0xFF4CAF50),
                  ),
                  title: const Text('Document Type'),
                  subtitle: Text(
                    _documentType.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Select Document Type'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: const Text('National ID'),
                              value: 'national_id',
                              groupValue: _documentType,
                              onChanged: (value) {
                                setState(() {
                                  _documentType = value!;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Passport'),
                              value: 'passport',
                              groupValue: _documentType,
                              onChanged: (value) {
                                setState(() {
                                  _documentType = value!;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Driver License'),
                              value: 'driver_license',
                              groupValue: _documentType,
                              onChanged: (value) {
                                setState(() {
                                  _documentType = value!;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Submit Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Submit for Verification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFA726).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verification usually takes 1-3 business days. You\'ll receive an email once your account is verified.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required IconData icon,
    String? imagePath,
    required VoidCallback onTap,
  }) {
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: imagePath != null
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: imagePath != null
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    if (imagePath != null) const SizedBox(height: 4),
                    if (imagePath != null)
                      Text(
                        'Uploaded',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                imagePath != null ? Icons.check_circle : Icons.upload_file,
                color: imagePath != null
                    ? const Color(0xFF4CAF50)
                    : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(String type) async {
    // Show image source selection dialog
    final source = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final file = await _imagePickerService.pickImage(fromCamera: source);

    if (file != null && mounted) {
      setState(() {
        switch (type) {
          case 'idFront':
            _idFrontFile = file;
            break;
          case 'idBack':
            _idBackFile = file;
            break;
          case 'selfie':
            _selfieFile = file;
            break;
        }
      });
    }
  }

  Future<void> _submitVerification() async {
    // Check if documents are already submitted and pending
    final status = _verificationStatus?['status'];
    final documentStatus = _verificationStatus?['document_status'];
    final hasSubmittedDocuments = _verificationStatus?['has_submitted_documents'] == true;
    
    if (status == 'pending' || 
        documentStatus == 'pending' || 
        hasSubmittedDocuments) {
      Fluttertoast.showToast(
        msg: 'You already have a pending verification request. Please wait for review.',
        backgroundColor: Colors.orange,
      );
      // Reload status to show pending screen
      await _loadVerificationStatus();
      return;
    }

    // Check if already verified
    if (status == 'verified') {
      Fluttertoast.showToast(
        msg: 'Your account is already verified',
        backgroundColor: Colors.green,
      );
      await _loadVerificationStatus();
      return;
    }

    // Check if all documents are uploaded
    if (_idFrontFile == null || _idBackFile == null || _selfieFile == null) {
      Fluttertoast.showToast(
        msg: 'Please upload ID front, ID back, and selfie with ID',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _verificationService.submitVerification(
        idFrontPath: _idFrontFile!.path,
        idBackPath: _idBackFile!.path,
        selfiePath: _selfieFile!.path,
        documentType: _documentType,
      );

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Verification submitted successfully',
          backgroundColor: Colors.green,
        );
        // Clear form data
        setState(() {
          _idFrontFile = null;
          _idBackFile = null;
          _selfieFile = null;
        });
        // Reload status to show pending screen
        await _loadVerificationStatus();
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
}
