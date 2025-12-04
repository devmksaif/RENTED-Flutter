import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  String? _idFrontPath;
  String? _idBackPath;
  String? _selfiePath;
  String? _addressProofPath;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(16),
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
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
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
              imagePath: _idFrontPath,
              onTap: () => _pickImage('idFront'),
            ),
            const SizedBox(height: 12),
            _buildUploadCard(
              title: 'Government ID (Back)',
              icon: Icons.credit_card,
              imagePath: _idBackPath,
              onTap: () => _pickImage('idBack'),
            ),
            const SizedBox(height: 12),
            _buildUploadCard(
              title: 'Selfie with ID',
              icon: Icons.face,
              imagePath: _selfiePath,
              onTap: () => _pickImage('selfie'),
            ),
            const SizedBox(height: 12),
            _buildUploadCard(
              title: 'Proof of Address',
              icon: Icons.description,
              imagePath: _addressProofPath,
              onTap: () => _pickImage('addressProof'),
            ),
            const SizedBox(height: 32),
            // Submit Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
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
                  color: const Color(0xFFFFA726).withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 22),
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
            color: Colors.black.withOpacity(0.05),
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
              color: const Color(0xFF4CAF50).withOpacity(0.1),
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
            color: Colors.black.withOpacity(0.05),
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
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
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
    // TODO: Implement actual image picker using image_picker package
    // For now, just simulate selecting an image
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      switch (type) {
        case 'idFront':
          _idFrontPath = 'path/to/id_front.jpg';
          break;
        case 'idBack':
          _idBackPath = 'path/to/id_back.jpg';
          break;
        case 'selfie':
          _selfiePath = 'path/to/selfie.jpg';
          break;
        case 'addressProof':
          _addressProofPath = 'path/to/address_proof.jpg';
          break;
      }
    });

    Fluttertoast.showToast(
      msg: 'Image upload will be available soon',
      backgroundColor: Colors.blue,
    );
  }

  Future<void> _submitVerification() async {
    // Check if all documents are uploaded
    if (_idFrontPath == null ||
        _idBackPath == null ||
        _selfiePath == null ||
        _addressProofPath == null) {
      Fluttertoast.showToast(
        msg: 'Please upload all required documents',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement actual verification submission
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: 'Verification submitted successfully',
        backgroundColor: Colors.green,
      );
      Navigator.pop(context);
    }
  }
}
