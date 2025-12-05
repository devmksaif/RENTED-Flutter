# Products Endpoints

## Overview

This document covers all product-related endpoints including browsing, viewing, and managing products.

---

## Get All Products

Retrieve a paginated list of all available products.

**Endpoint**: `GET /products`

**Authentication**: Not required

**Query Parameters**:

- `page` (integer, optional): Page number (default: 1)
- `per_page` (integer, optional): Items per page (default: 15, max: 100)

**Request Example**:

```bash
GET /products?page=2&per_page=20
```

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": 1,
      "title": "Canon EOS R5 Camera",
      "description": "Professional mirrorless camera",
      "price_per_day": "50.00",
      "is_for_sale": true,
      "sale_price": "2500.00",
      "is_available": true,
      "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/camera1.jpg",
      "image_urls": [
        "http://localhost:8000/storage/products/images/camera1-1.jpg",
        "http://localhost:8000/storage/products/images/camera1-2.jpg"
      ],
      "category": {
        "id": 2,
        "name": "Photography",
        "slug": "photography"
      }
    }
  ],
  "links": {
    "first": "http://localhost:8000/api/v1/products?page=1",
    "last": "http://localhost:8000/api/v1/products?page=10",
    "prev": "http://localhost:8000/api/v1/products?page=1",
    "next": "http://localhost:8000/api/v1/products?page=3"
  },
  "meta": {
    "current_page": 2,
    "from": 16,
    "last_page": 10,
    "per_page": 15,
    "to": 30,
    "total": 150
  }
}
```

**Cache**: This endpoint is cached for 10 minutes.

---

## Get Single Product

Retrieve details of a specific product.

**Endpoint**: `GET /products/{id}`

**Authentication**: Not required

**Path Parameters**:

- `id` (integer, required): Product ID

**Response** (200 OK):

```json
{
  "data": {
    "id": 1,
    "title": "Canon EOS R5 Camera",
    "description": "Professional mirrorless camera with 45MP full-frame sensor",
    "price_per_day": "50.00",
    "is_for_sale": true,
    "sale_price": "2500.00",
    "is_available": true,
    "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/camera1.jpg",
    "image_urls": [
      "http://localhost:8000/storage/products/images/camera1-1.jpg",
      "http://localhost:8000/storage/products/images/camera1-2.jpg",
      "http://localhost:8000/storage/products/images/camera1-3.jpg"
    ],
    "category": {
      "id": 2,
      "name": "Photography",
      "slug": "photography",
      "description": "Cameras, lenses, and photography equipment"
    },
    "owner": {
      "id": 5,
      "name": "Jane Smith",
      "email": "jane.smith@example.com",
      "avatar_url": "http://localhost:8000/storage/avatars/5_xyz789.jpg"
    },
    "created_at": "2025-12-01T10:30:00.000000Z",
    "updated_at": "2025-12-02T14:20:00.000000Z"
  }
}
```

**Error Responses**:

*404 Not Found* - Product doesn't exist

```json
{
  "message": "Resource not found."
}
```

**Cache**: This endpoint is cached for 10 minutes.

---

## Create Product

Create a new product listing with images. **Requires verified user**.

**Endpoint**: `POST /products`

**Authentication**: Required (Verified users only)

**Headers**:

```http
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request Body** (multipart/form-data):

- `category_id` (integer, required): Category ID
- `title` (string, required): Product title
- `description` (string, required): Product description
- `price_per_day` (numeric, required): Daily rental price
- `is_for_sale` (boolean, optional): Is product for sale? (default: false)
- `sale_price` (numeric, required_if:is_for_sale): Sale price (required if is_for_sale is true)
- `images` (array, optional): Product images (1-5 images, each max 2MB)

**Validation Rules**:

- `category_id`: required, exists:categories,id
- `title`: required, string, max:255
- `description`: required, string
- `price_per_day`: required, numeric, min:1
- `is_for_sale`: boolean
- `sale_price`: required_if:is_for_sale,true, numeric, min:1
- `images`: nullable, array, min:1, max:5
- `images.*`: image, mimes:jpeg,jpg,png, max:2048

**cURL Example**:

```bash
curl -X POST "http://localhost:8000/api/v1/products" \
  -H "Authorization: Bearer {token}" \
  -H "Accept: application/json" \
  -F "category_id=2" \
  -F "title=Canon EOS R5 Camera" \
  -F "description=Professional mirrorless camera with 45MP sensor" \
  -F "price_per_day=50" \
  -F "is_for_sale=true" \
  -F "sale_price=2500" \
  -F "images[]=@/path/to/image1.jpg" \
  -F "images[]=@/path/to/image2.jpg" \
  -F "images[]=@/path/to/image3.jpg"
```

**Response** (201 Created):

```json
{
  "message": "Product created successfully",
  "data": {
    "id": 25,
    "title": "Canon EOS R5 Camera",
    "description": "Professional mirrorless camera with 45MP sensor",
    "price_per_day": "50.00",
    "is_for_sale": true,
    "sale_price": "2500.00",
    "is_available": true,
    "verification_status": "pending",
    "thumbnail_url": null,
    "image_urls": [
      "http://localhost:8000/storage/products/images/abc123xyz.jpg",
      "http://localhost:8000/storage/products/images/def456uvw.jpg",
      "http://localhost:8000/storage/products/images/ghi789rst.jpg"
    ],
    "category": {
      "id": 2,
      "name": "Photography",
      "slug": "photography"
    },
    "owner": {
      "id": 1,
      "name": "John Doe",
      "email": "john.doe@example.com",
      "avatar_url": "http://localhost:8000/storage/avatars/user1.jpg"
    },
    "created_at": "2025-12-03T14:30:45.000000Z",
    "updated_at": "2025-12-03T14:30:45.000000Z"
  }
}
```

**Important Notes**:
- ⚠️ **New products require approval**: All newly created products have `verification_status: "pending"` and will NOT appear in public listings until approved by an admin/moderator
- Products are automatically set to `is_available: true` but won't be visible until verified
- Users can view their own pending products via `/user/products`
- Admin approval typically takes 24-48 hours
- Once approved, products appear in public `/products` endpoint

**Error Responses**:

*403 Forbidden* - User not verified

```json
{
  "message": "Your account must be verified to perform this action."
}
```

*422 Unprocessable Entity* - Validation failed

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "title": [
      "The title field is required."
    ],
    "sale_price": [
      "The sale price field is required when is for sale is true."
    ],
    "images": [
      "You can upload a maximum of 5 images."
    ],
    "images.0": [
      "The images.0 must be an image.",
      "The images.0 must not be greater than 2048 kilobytes."
    ]
  }
}
```

**Flutter Implementation Example**:

```dart
Future<Map<String, dynamic>> createProduct({
  required int categoryId,
  required String title,
  required String description,
  required double pricePerDay,
  bool isForSale = false,
  double? salePrice,
  List<File>? images,
}) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/products'),
  );

  request.headers.addAll({
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  });

  request.fields['category_id'] = categoryId.toString();
  request.fields['title'] = title;
  request.fields['description'] = description;
  request.fields['price_per_day'] = pricePerDay.toString();
  request.fields['is_for_sale'] = isForSale ? '1' : '0';
  
  if (isForSale && salePrice != null) {
    request.fields['sale_price'] = salePrice.toString();
  }

  // Add images (max 5)
  if (images != null && images.isNotEmpty) {
    for (var i = 0; i < images.length && i < 5; i++) {
      request.files.add(await http.MultipartFile.fromPath(
        'images[]',
        images[i].path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }
  }

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();
  
  if (response.statusCode == 201) {
    return json.decode(responseBody);
  } else if (response.statusCode == 403) {
    throw Exception('Your account must be verified to create products');
  } else if (response.statusCode == 422) {
    final errors = json.decode(responseBody);
    throw Exception(errors['message']);
  }
  
  throw Exception('Failed to create product');
}
```

---

## Update Product

Update an existing product. **Only product owner can update**. When updating with new images, old images are automatically deleted.

**Endpoint**: `PUT /products/{id}` or `PATCH /products/{id}`

**Authentication**: Required (Product owner only)

**Headers**:

```http
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Path Parameters**:

- `id` (integer, required): Product ID

**Request Body** (multipart/form-data):

All fields are optional. Include only the fields you want to update.

- `category_id` (integer, optional): Category ID
- `title` (string, optional): Product title
- `description` (string, optional): Product description
- `price_per_day` (numeric, optional): Daily rental price
- `is_for_sale` (boolean, optional): Is product for sale?
- `sale_price` (numeric, optional): Sale price
- `is_available` (boolean, optional): Product availability status
- `images` (array, optional): New product images (1-5 images, replaces all old images)

**Validation Rules**:

- `category_id`: sometimes, exists:categories,id
- `title`: sometimes, string, max:255
- `description`: sometimes, string
- `price_per_day`: sometimes, numeric, min:1
- `is_for_sale`: boolean
- `sale_price`: required_if:is_for_sale,true, numeric, min:1
- `is_available`: boolean
- `images`: nullable, array, min:1, max:5
- `images.*`: image, mimes:jpeg,jpg,png, max:2048

**cURL Example** (Update text fields only):

```bash
curl -X PUT "http://localhost:8000/api/v1/products/25" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "title": "Updated Camera Title",
    "price_per_day": 55.00,
    "is_available": true
  }'
```

**cURL Example** (Update with new images):

```bash
curl -X POST "http://localhost:8000/api/v1/products/25" \
  -H "Authorization: Bearer {token}" \
  -H "Accept: application/json" \
  -F "_method=PUT" \
  -F "title=Updated Camera Title" \
  -F "price_per_day=55" \
  -F "images[]=@/path/to/new_image1.jpg" \
  -F "images[]=@/path/to/new_image2.jpg"
```

**Response** (200 OK):

```json
{
  "message": "Product updated successfully",
  "data": {
    "id": 25,
    "title": "Updated Camera Title",
    "description": "Professional mirrorless camera with 45MP sensor",
    "price_per_day": "55.00",
    "is_for_sale": true,
    "sale_price": "2500.00",
    "is_available": true,
    "thumbnail_url": null,
    "image_urls": [
      "http://localhost:8000/storage/products/images/new_abc123.jpg",
      "http://localhost:8000/storage/products/images/new_def456.jpg"
    ],
    "category": {
      "id": 2,
      "name": "Photography",
      "slug": "photography"
    },
    "owner": {
      "id": 1,
      "name": "John Doe",
      "email": "john.doe@example.com",
      "avatar_url": "http://localhost:8000/storage/avatars/user1.jpg"
    },
    "created_at": "2025-12-03T14:30:45.000000Z",
    "updated_at": "2025-12-03T15:30:45.000000Z"
  }
}
```

**Error Responses**:

*403 Forbidden* - Not product owner

```json
{
  "message": "This action is unauthorized."
}
```

*404 Not Found* - Product doesn't exist

```json
{
  "message": "Product not found"
}
```

*422 Unprocessable Entity* - Validation failed

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "price_per_day": [
      "The price per day must be at least 1."
    ],
    "images": [
      "You can upload a maximum of 5 images."
    ]
  }
}
```

**Flutter Implementation Example**:

```dart
Future<Map<String, dynamic>> updateProduct({
  required int productId,
  String? title,
  String? description,
  double? pricePerDay,
  bool? isAvailable,
  List<File>? newImages,
}) async {
  // For text-only updates
  if (newImages == null || newImages.isEmpty) {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (pricePerDay != null) 'price_per_day': pricePerDay,
        if (isAvailable != null) 'is_available': isAvailable,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update product');
  }

  // For updates with images
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/products/$productId'),
  );

  request.headers.addAll({
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  });

  request.fields['_method'] = 'PUT';
  if (title != null) request.fields['title'] = title;
  if (description != null) request.fields['description'] = description;
  if (pricePerDay != null) request.fields['price_per_day'] = pricePerDay.toString();
  if (isAvailable != null) request.fields['is_available'] = isAvailable ? '1' : '0';

  // Add new images (replaces all old images)
  for (var i = 0; i < newImages.length && i < 5; i++) {
    request.files.add(await http.MultipartFile.fromPath(
      'images[]',
      newImages[i].path,
      contentType: MediaType('image', 'jpeg'),
    ));
  }

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();
  
  if (response.statusCode == 200) {
    return json.decode(responseBody);
  } else if (response.statusCode == 403) {
    throw Exception('Unauthorized: You can only update your own products');
  }
  
  throw Exception('Failed to update product');
}
```

---

## Delete Product

Delete a product listing. **Only product owner can delete**. All product images are automatically deleted from storage.

**Endpoint**: `DELETE /products/{id}`

**Authentication**: Required (Product owner only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Path Parameters**:

- `id` (integer, required): Product ID

**Response** (200 OK):

```json
{
  "message": "Product deleted successfully"
}
```

**Note**: All product images are automatically deleted from storage.

**Error Responses**:

*403 Forbidden* - Not product owner

```json
{
  "message": "This action is unauthorized."
}
```

*404 Not Found* - Product doesn't exist

```json
{
  "message": "Product not found"
}
```

**Flutter Implementation Example**:

```dart
Future<void> deleteProduct(int productId) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/products/$productId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print(data['message']); // "Product deleted successfully"
    return;
  } else if (response.statusCode == 403) {
    throw Exception('Unauthorized: You can only delete your own products');
  } else if (response.statusCode == 404) {
    throw Exception('Product not found');
  }
  
  throw Exception('Failed to delete product');
}
```

---

## Get User's Products

Retrieve all products belonging to the authenticated user.

**Endpoint**: `GET /user/products`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": 25,
      "title": "Canon EOS R5 Camera",
      "description": "Professional mirrorless camera",
      "price_per_day": "50.00",
      "is_for_sale": true,
      "sale_price": "2500.00",
      "is_available": true,
      "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/abc123.jpg",
      "image_urls": [
        "http://localhost:8000/storage/products/images/xyz789.jpg"
      ],
      "category": {
        "id": 2,
        "name": "Photography"
      },
      "created_at": "2025-12-03T14:30:45.000000Z"
    }
  ]
}
```

---
