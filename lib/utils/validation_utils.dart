/// Input validation utilities for forms
class ValidationUtils {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Phone number validation (Indian format)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check for 10 digits (Indian mobile)
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid 10-digit phone number';
    }
    
    return null;
  }

  // Price validation
  static String? validatePrice(String? value, {bool allowZero = false}) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    final price = double.tryParse(value);
    
    if (price == null) {
      return 'Please enter a valid number';
    }
    
    if (!allowZero && price <= 0) {
      return 'Price must be greater than 0';
    }
    
    if (price < 0) {
      return 'Price cannot be negative';
    }
    
    if (price > 10000000) {
      return 'Price cannot exceed ₹1 Crore';
    }
    
    return null;
  }

  // Quantity validation
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    
    final quantity = int.tryParse(value);
    
    if (quantity == null) {
      return 'Please enter a valid whole number';
    }
    
    if (quantity <= 0) {
      return 'Quantity must be at least 1';
    }
    
    if (quantity > 100000) {
      return 'Quantity cannot exceed 100,000';
    }
    
    return null;
  }

  // Decimal quantity validation (for weighted products)
  static String? validateDecimalQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    
    final quantity = double.tryParse(value);
    
    if (quantity == null) {
      return 'Please enter a valid number';
    }
    
    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }
    
    if (quantity > 100000) {
      return 'Quantity cannot exceed 100,000';
    }
    
    return null;
  }

  // Barcode validation
  static String? validateBarcode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Barcode is required';
    }
    
    // Remove spaces
    final cleaned = value.replaceAll(' ', '');
    
    // Check length (EAN-13, EAN-8, UPC-A, UPC-E)
    if (cleaned.length != 8 && 
        cleaned.length != 12 && 
        cleaned.length != 13) {
      return 'Barcode must be 8, 12, or 13 digits';
    }
    
    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Barcode must contain only numbers';
    }
    
    return null;
  }

  // SKU validation
  static String? validateSKU(String? value) {
    if (value == null || value.isEmpty) {
      return 'SKU is required';
    }
    
    if (value.length < 3) {
      return 'SKU must be at least 3 characters';
    }
    
    if (value.length > 50) {
      return 'SKU cannot exceed 50 characters';
    }
    
    // Allow alphanumeric, hyphens, and underscores
    if (!RegExp(r'^[a-zA-Z0-9-_]+$').hasMatch(value)) {
      return 'SKU can only contain letters, numbers, hyphens, and underscores';
    }
    
    return null;
  }

  // Product name validation
  static String? validateProductName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Product name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Product name must be at least 2 characters';
    }
    
    if (value.length > 100) {
      return 'Product name cannot exceed 100 characters';
    }
    
    return null;
  }

  // Store name validation
  static String? validateStoreName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Store name is required';
    }
    
    if (value.trim().length < 3) {
      return 'Store name must be at least 3 characters';
    }
    
    if (value.length > 100) {
      return 'Store name cannot exceed 100 characters';
    }
    
    return null;
  }

  // Tax percentage validation
  static String? validateTaxPercentage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tax percentage is required';
    }
    
    final tax = double.tryParse(value);
    
    if (tax == null) {
      return 'Please enter a valid number';
    }
    
    if (tax < 0) {
      return 'Tax percentage cannot be negative';
    }
    
    if (tax > 100) {
      return 'Tax percentage cannot exceed 100%';
    }
    
    return null;
  }

  // GSTIN validation (Indian tax number)
  static String? validateGSTIN(String? value) {
    if (value == null || value.isEmpty) {
      return null; // GSTIN is optional
    }
    
    // GSTIN format: 22AAAAA0000A1Z5
    final gstinRegex = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
    );
    
    if (!gstinRegex.hasMatch(value.toUpperCase())) {
      return 'Please enter a valid GSTIN (e.g., 22AAAAA0000A1Z5)';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Minimum length validation
  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }

  // Maximum length validation
  static String? validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value != null && value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    
    return null;
  }

  // Percentage validation (0-100)
  static String? validatePercentage(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final percentage = double.tryParse(value);
    
    if (percentage == null) {
      return 'Please enter a valid number';
    }
    
    if (percentage < 0 || percentage > 100) {
      return '$fieldName must be between 0 and 100';
    }
    
    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }

  // Non-negative number validation
  static String? validateNonNegativeNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number < 0) {
      return '$fieldName cannot be negative';
    }
    
    return null;
  }
}
