import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../models/api_error.dart';
import '../services/product_service.dart';
import '../config/app_theme.dart';

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
        isForSale: _isForSale,
        salePrice: _salePriceController.text.isNotEmpty
            ? double.tryParse(_salePriceController.text)
            : null,
        newImagePaths: imagePaths,
      );
      
      // Note: Additional fields like delivery, pickup, condition, etc.
      // can be added to the updateProduct method if needed

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
