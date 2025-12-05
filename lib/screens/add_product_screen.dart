import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/api_error.dart';
import '../providers/product_provider.dart';
import '../config/app_theme.dart';
import '../services/storage_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();
  final StorageService _storageService = StorageService();
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Form Controllers - Step 1: Basic Info
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _salePriceController = TextEditingController();

  // Form Controllers - Step 2: Pricing & Rental Terms
  final _pricePerWeekController = TextEditingController();
  final _pricePerMonthController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _minRentalDaysController = TextEditingController();
  final _maxRentalDaysController = TextEditingController();

  // Form Controllers - Step 3: Location
  final _locationAddressController = TextEditingController();
  final _locationCityController = TextEditingController();
  final _locationStateController = TextEditingController();
  final _locationCountryController = TextEditingController();
  final _locationZipController = TextEditingController();
  final _locationLatitudeController = TextEditingController();
  final _locationLongitudeController = TextEditingController();

  // Form Controllers - Step 4: Delivery Options
  final _deliveryFeeController = TextEditingController();
  final _deliveryRadiusController = TextEditingController();

  // Form State
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isForSale = false;
  bool? _deliveryAvailable;
  bool? _pickupAvailable;
  String? _productCondition; // new, like_new, good, fair, worn
  bool _isLoading = false;
  bool _loadingCategories = true;
  final List<File> _imageFiles = [];

  // Form Keys for validation
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();
  final _step4FormKey = GlobalKey<FormState>();
  final _step5FormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      await productProvider.loadCategories();

      if (mounted) {
        setState(() {
          _categories = productProvider.categories;
          _loadingCategories = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          for (final image in images) {
            if (_imageFiles.length < 5) {
              _imageFiles.add(File(image.path));
            }
          }
        });

        if (images.length > (5 - _imageFiles.length)) {
          Fluttertoast.showToast(
            msg: 'Only 5 images allowed. Some images were not added.',
            backgroundColor: Colors.orange,
          );
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to pick images: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  void _nextStep() {
    // Validate current step before proceeding
    bool isValid = true;
    switch (_currentStep) {
      case 0:
        isValid = _step1FormKey.currentState?.validate() ?? false;
        break;
      case 1:
        isValid = _step2FormKey.currentState?.validate() ?? false;
        break;
      case 2:
        isValid = _step3FormKey.currentState?.validate() ?? false;
        break;
      case 3:
        isValid = _step4FormKey.currentState?.validate() ?? false;
        break;
      case 4:
        isValid = _step5FormKey.currentState?.validate() ?? false;
        if (_imageFiles.isEmpty) {
          Fluttertoast.showToast(
            msg: 'Please add at least one image',
            backgroundColor: Colors.red,
          );
          isValid = false;
        }
        break;
    }

    if (isValid && _currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _pricePerDayController.dispose();
    _salePriceController.dispose();
    _pricePerWeekController.dispose();
    _pricePerMonthController.dispose();
    _securityDepositController.dispose();
    _minRentalDaysController.dispose();
    _maxRentalDaysController.dispose();
    _locationAddressController.dispose();
    _locationCityController.dispose();
    _locationStateController.dispose();
    _locationCountryController.dispose();
    _locationZipController.dispose();
    _locationLatitudeController.dispose();
    _locationLongitudeController.dispose();
    _deliveryFeeController.dispose();
    _deliveryRadiusController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    // Check if user is verified
    final currentUser = await _storageService.getUser();
    if (currentUser == null) {
      Fluttertoast.showToast(
        msg: 'You must be logged in to create a product',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (!currentUser.isVerified) {
      Fluttertoast.showToast(
        msg: 'You must be verified to create products. Please complete your verification first.',
        backgroundColor: Colors.orange,
        toastLength: Toast.LENGTH_LONG,
      );
      // Optionally navigate to verification screen
      return;
    }

    if (_imageFiles.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please add at least one image',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Fluttertoast.showToast(
        msg: 'Uploading product...',
        backgroundColor: Colors.blue,
        toastLength: Toast.LENGTH_SHORT,
      );

      final allImages = _imageFiles.map((f) => f.path).toList();

      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      await productProvider.createProduct(
        categoryId: _selectedCategoryId!,
        title: _titleController.text,
        description: _descriptionController.text,
        pricePerDay: double.parse(_pricePerDayController.text),
        isForSale: _isForSale,
        salePrice: _isForSale && _salePriceController.text.isNotEmpty
            ? double.parse(_salePriceController.text)
            : null,
        pricePerWeek: _pricePerWeekController.text.isNotEmpty
            ? double.tryParse(_pricePerWeekController.text)
            : null,
        pricePerMonth: _pricePerMonthController.text.isNotEmpty
            ? double.tryParse(_pricePerMonthController.text)
            : null,
        securityDeposit: _securityDepositController.text.isNotEmpty
            ? double.tryParse(_securityDepositController.text)
            : null,
        minRentalDays: _minRentalDaysController.text.isNotEmpty
            ? int.tryParse(_minRentalDaysController.text)
            : null,
        maxRentalDays: _maxRentalDaysController.text.isNotEmpty
            ? int.tryParse(_maxRentalDaysController.text)
            : null,
        locationAddress: _locationAddressController.text.isNotEmpty
            ? _locationAddressController.text
            : null,
        locationCity: _locationCityController.text.isNotEmpty
            ? _locationCityController.text
            : null,
        locationState: _locationStateController.text.isNotEmpty
            ? _locationStateController.text
            : null,
        locationCountry: _locationCountryController.text.isNotEmpty
            ? _locationCountryController.text
            : null,
        locationZip: _locationZipController.text.isNotEmpty
            ? _locationZipController.text
            : null,
        locationLatitude: _locationLatitudeController.text.isNotEmpty
            ? double.tryParse(_locationLatitudeController.text)
            : null,
        locationLongitude: _locationLongitudeController.text.isNotEmpty
            ? double.tryParse(_locationLongitudeController.text)
            : null,
        deliveryAvailable: _deliveryAvailable,
        deliveryFee: _deliveryFeeController.text.isNotEmpty
            ? double.tryParse(_deliveryFeeController.text)
            : null,
        deliveryRadiusKm: _deliveryRadiusController.text.isNotEmpty
            ? double.tryParse(_deliveryRadiusController.text)
            : null,
        pickupAvailable: _pickupAvailable,
        productCondition: _productCondition,
        imagePaths: allImages,
      );

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Product created successfully',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context, true);
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: e.message,
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive || isCompleted
                    ? AppTheme.primaryGreen
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final stepNames = [
      'Basic Info',
      'Pricing',
      'Location',
      'Delivery',
      'Details',
      'Review'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive || isCompleted
                        ? AppTheme.primaryGreen
                        : Colors.grey[300],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stepNames[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive || isCompleted
                        ? AppTheme.primaryGreen
                        : Colors.grey[600],
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1BasicInfo() {
    return Form(
      key: _step1FormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _titleController,
              label: 'Product Title',
              hint: 'Enter product title',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownField<int>(
              value: _selectedCategoryId,
              label: 'Category',
              icon: Icons.category,
              items: _categories.map((category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Enter product description',
              icon: Icons.description,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _pricePerDayController,
              label: 'Price Per Day',
              hint: 'Enter rental price per day',
              icon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Available for Sale',
              subtitle: 'Allow users to purchase this product',
              value: _isForSale,
              onChanged: (value) {
                setState(() {
                  _isForSale = value;
                });
              },
            ),
            if (_isForSale) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _salePriceController,
                label: 'Sale Price',
                hint: 'Enter sale price',
                icon: Icons.shopping_cart,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (_isForSale && (value == null || value.isEmpty)) {
                    return 'Please enter a sale price';
                  }
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Pricing() {
    return Form(
      key: _step2FormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Pricing & Rental Terms'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _pricePerWeekController,
              label: 'Price Per Week (Optional)',
              hint: 'Enter weekly rental price',
              icon: Icons.calendar_view_week,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _pricePerMonthController,
              label: 'Price Per Month (Optional)',
              hint: 'Enter monthly rental price',
              icon: Icons.calendar_month,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _securityDepositController,
              label: 'Security Deposit (Optional)',
              hint: 'Enter security deposit amount',
              icon: Icons.security,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _minRentalDaysController,
              label: 'Minimum Rental Days (Optional)',
              hint: 'e.g., 3',
              icon: Icons.event_busy,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _maxRentalDaysController,
              label: 'Maximum Rental Days (Optional)',
              hint: 'e.g., 30',
              icon: Icons.event_available,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Location() {
    return Form(
      key: _step3FormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Location Information'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationAddressController,
              label: 'Street Address (Optional)',
              hint: 'Enter street address',
              icon: Icons.location_on,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationCityController,
              label: 'City (Optional)',
              hint: 'Enter city',
              icon: Icons.location_city,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationStateController,
              label: 'State/Province (Optional)',
              hint: 'Enter state or province',
              icon: Icons.map,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationCountryController,
              label: 'Country (Optional)',
              hint: 'Enter country',
              icon: Icons.public,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationZipController,
              label: 'Postal Code (Optional)',
              hint: 'Enter postal code',
              icon: Icons.markunread_mailbox,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _locationLatitudeController,
                    label: 'Latitude (Optional)',
                    hint: 'e.g., 40.7128',
                    icon: Icons.explore,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _locationLongitudeController,
                    label: 'Longitude (Optional)',
                    hint: 'e.g., -74.0060',
                    icon: Icons.explore,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Delivery() {
    return Form(
      key: _step4FormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Delivery Options'),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Delivery Available',
              subtitle: 'Offer delivery service for this product',
              value: _deliveryAvailable ?? false,
              onChanged: (value) {
                setState(() {
                  _deliveryAvailable = value;
                });
              },
            ),
            if (_deliveryAvailable == true) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _deliveryFeeController,
                label: 'Delivery Fee (Optional)',
                hint: 'Enter delivery fee amount',
                icon: Icons.local_shipping,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _deliveryRadiusController,
                label: 'Delivery Radius (km) (Optional)',
                hint: 'Enter delivery radius in kilometers',
                icon: Icons.radio_button_checked,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Pickup Available',
              subtitle: 'Allow customers to pick up the product',
              value: _pickupAvailable ?? false,
              onChanged: (value) {
                setState(() {
                  _pickupAvailable = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5Details() {
    return Form(
      key: _step5FormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Product Details'),
            const SizedBox(height: 16),
            _buildDropdownField<String>(
              value: _productCondition,
              label: 'Product Condition (Optional)',
              icon: Icons.check_circle_outline,
              items: const [
                DropdownMenuItem(value: 'new', child: Text('New')),
                DropdownMenuItem(value: 'like_new', child: Text('Like New')),
                DropdownMenuItem(value: 'good', child: Text('Good')),
                DropdownMenuItem(value: 'fair', child: Text('Fair')),
                DropdownMenuItem(value: 'worn', child: Text('Worn')),
              ],
              onChanged: (value) {
                setState(() {
                  _productCondition = value;
                });
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Product Images (${_imageFiles.length}/5)'),
            const SizedBox(height: 16),
            if (_imageFiles.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imageFiles[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _imageFiles.length < 5 ? _pickImages : null,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (_imageFiles.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'At least one image is required',
                  style: TextStyle(color: Colors.red[600], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep6Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Review Your Product'),
          const SizedBox(height: 16),
          _buildReviewCard('Title', _titleController.text),
          _buildReviewCard('Category', _categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => _categories.first).name),
          _buildReviewCard('Description', _descriptionController.text),
          _buildReviewCard('Price Per Day', '\$${_pricePerDayController.text}'),
          if (_pricePerWeekController.text.isNotEmpty)
            _buildReviewCard('Price Per Week', '\$${_pricePerWeekController.text}'),
          if (_pricePerMonthController.text.isNotEmpty)
            _buildReviewCard('Price Per Month', '\$${_pricePerMonthController.text}'),
          if (_isForSale)
            _buildReviewCard('Sale Price', '\$${_salePriceController.text}'),
          if (_securityDepositController.text.isNotEmpty)
            _buildReviewCard('Security Deposit', '\$${_securityDepositController.text}'),
          if (_locationCityController.text.isNotEmpty)
            _buildReviewCard('Location', '${_locationCityController.text}, ${_locationStateController.text.isNotEmpty ? _locationStateController.text : ''}'),
          if (_deliveryAvailable == true)
            _buildReviewCard('Delivery', 'Available${_deliveryFeeController.text.isNotEmpty ? ' - \$${_deliveryFeeController.text}' : ''}'),
          if (_pickupAvailable == true)
            _buildReviewCard('Pickup', 'Available'),
          if (_productCondition != null)
            _buildReviewCard('Condition', _productCondition!.replaceAll('_', ' ').toUpperCase()),
          _buildReviewCard('Images', '${_imageFiles.length} image(s)'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
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
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
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
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildReviewCard(String label, String value) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Add New Product (${_currentStep + 1}/$_totalSteps)',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressIndicator(),
                _buildStepIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1BasicInfo(),
                      _buildStep2Pricing(),
                      _buildStep3Location(),
                      _buildStep4Delivery(),
                      _buildStep5Details(),
                      _buildStep6Review(),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppTheme.primaryGreen),
                            ),
                            child: const Text('Previous'),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: _currentStep == 0 ? 1 : 1,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_currentStep == _totalSteps - 1
                                  ? _submitProduct
                                  : _nextStep),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primaryGreen,
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
                              : Text(
                                  _currentStep == _totalSteps - 1
                                      ? 'Create Product'
                                      : 'Next',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
