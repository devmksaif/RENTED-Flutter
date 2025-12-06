import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../models/api_error.dart';
import '../services/product_service.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

class EditProductScreen extends StatefulWidget {
  final int productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final ProductService _productService = ProductService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  Product? _product;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _pricePerWeekController = TextEditingController();
  final _pricePerMonthController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _minRentalDaysController = TextEditingController();
  final _maxRentalDaysController = TextEditingController();
  final _locationAddressController = TextEditingController();
  final _locationCityController = TextEditingController();
  final _locationStateController = TextEditingController();
  final _locationCountryController = TextEditingController();
  final _locationZipController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _deliveryRadiusController = TextEditingController();

  // Form State
  int? _selectedCategoryId;
  bool _isForSale = false;
  bool? _deliveryAvailable;
  bool? _pickupAvailable;
  String? _productCondition;
  final _locationLatitudeController = TextEditingController();
  final _locationLongitudeController = TextEditingController();
  List<File> _newImageFiles = [];
  List<String> _existingImageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
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

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final product = await _productService.getProduct(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _populateForm(product);
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
        Navigator.pop(context);
      }
    }
  }

  void _populateForm(Product product) {
    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _pricePerDayController.text = product.pricePerDay;
    _selectedCategoryId = product.category.id;
    _isForSale = product.isForSale;
    _salePriceController.text = product.salePrice ?? '';
    _pricePerWeekController.text = product.pricePerWeek ?? '';
    _pricePerMonthController.text = product.pricePerMonth ?? '';
    _securityDepositController.text = product.securityDeposit ?? '';
    _minRentalDaysController.text = product.minRentalDays?.toString() ?? '';
    _maxRentalDaysController.text = product.maxRentalDays?.toString() ?? '';
    _locationAddressController.text = product.locationAddress ?? '';
    _locationCityController.text = product.locationCity ?? '';
    _locationStateController.text = product.locationState ?? '';
    _locationCountryController.text = product.locationCountry ?? '';
    _locationZipController.text = product.locationZip ?? '';
    _locationLatitudeController.text = product.locationLatitude?.toString() ?? '';
    _locationLongitudeController.text = product.locationLongitude?.toString() ?? '';
    _deliveryAvailable = product.deliveryAvailable;
    _pickupAvailable = product.pickupAvailable;
    _productCondition = product.productCondition;
    _deliveryFeeController.text = product.deliveryFee ?? '';
    _deliveryRadiusController.text = product.deliveryRadiusKm?.toString() ?? '';
    _existingImageUrls = List.from(product.images);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _newImageFiles.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error picking images: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      List<String>? imagePaths;
      if (_newImageFiles.isNotEmpty) {
        // If new images are added, we need to upload them
        // For now, we'll use the updateProduct with newImagePaths
        imagePaths = _newImageFiles.map((f) => f.path).toList();
      } else if (_existingImageUrls.isEmpty) {
        Fluttertoast.showToast(
          msg: 'At least one image is required',
          backgroundColor: Colors.red,
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      await _productService.updateProduct(
        productId: widget.productId,
        categoryId: _selectedCategoryId,
        title: _titleController.text,
        description: _descriptionController.text,
        pricePerDay: double.parse(_pricePerDayController.text),
        pricePerWeek: _pricePerWeekController.text.isNotEmpty
            ? double.tryParse(_pricePerWeekController.text)
            : null,
        pricePerMonth: _pricePerMonthController.text.isNotEmpty
            ? double.tryParse(_pricePerMonthController.text)
            : null,
        isForSale: _isForSale,
        salePrice: _salePriceController.text.isNotEmpty
            ? double.tryParse(_salePriceController.text)
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
        securityDeposit: _securityDepositController.text.isNotEmpty
            ? double.tryParse(_securityDepositController.text)
            : null,
        minRentalDays: _minRentalDaysController.text.isNotEmpty
            ? int.tryParse(_minRentalDaysController.text)
            : null,
        maxRentalDays: _maxRentalDaysController.text.isNotEmpty
            ? int.tryParse(_maxRentalDaysController.text)
            : null,
        newImagePaths: imagePaths,
      );

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Product updated successfully',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context, true);
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Product'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text('Product not found'))
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Basic Info
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
                        SwitchListTile(
                          title: const Text('Available for Sale'),
                          subtitle: const Text('Allow users to purchase this product'),
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
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Pricing Section
                        Text(
                          'Additional Pricing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _minRentalDaysController,
                                label: 'Min Rental Days',
                                hint: 'e.g., 3',
                                icon: Icons.event_busy,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _maxRentalDaysController,
                                label: 'Max Rental Days',
                                hint: 'e.g., 30',
                                icon: Icons.event_available,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Location Section
                        Text(
                          'Location Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _locationStateController,
                                label: 'State/Province',
                                hint: 'Enter state',
                                icon: Icons.map,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _locationZipController,
                                label: 'Postal Code',
                                hint: 'Enter zip',
                                icon: Icons.markunread_mailbox,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _locationCountryController,
                          label: 'Country (Optional)',
                          hint: 'Enter country',
                          icon: Icons.public,
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
                        const SizedBox(height: 24),
                        // Delivery & Pickup Section
                        Text(
                          'Delivery & Pickup Options',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Delivery Available'),
                          subtitle: const Text('Offer delivery service for this product'),
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
                        SwitchListTile(
                          title: const Text('Pickup Available'),
                          subtitle: const Text('Allow customers to pick up the product'),
                          value: _pickupAvailable ?? false,
                          onChanged: (value) {
                            setState(() {
                              _pickupAvailable = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        // Product Condition
                        Text(
                          'Product Condition',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _productCondition,
                          decoration: InputDecoration(
                            labelText: 'Product Condition (Optional)',
                            prefixIcon: Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor,
                          ),
                          dropdownColor: theme.cardColor,
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
                        // Images Section
                        Text(
                          'Product Images',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Existing Images
                        if (_existingImageUrls.isNotEmpty)
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _existingImageUrls.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _existingImageUrls[index],
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 120,
                                            height: 120,
                                            color: theme.cardColor,
                                            child: Icon(Icons.image_not_supported, color: theme.hintColor),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeExistingImage(index),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: AppTheme.errorRed,
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
                        // New Images
                        if (_newImageFiles.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _newImageFiles.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _newImageFiles[index],
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeNewImage(index),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: AppTheme.errorRed,
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
                        ],
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add New Images'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Save Button
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
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
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
    );
  }
}
