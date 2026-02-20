/// User-friendly error message handler
class ErrorMessageHandler {
  /// Convert technical errors to user-friendly messages
  static String getFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    
    // Firebase errors
    if (errorString.contains('permission-denied')) {
      return 'You don\'t have permission to perform this action.';
    }
    
    if (errorString.contains('not-found')) {
      return 'The requested item was not found.';
    }
    
    if (errorString.contains('already-exists')) {
      return 'This item already exists.';
    }
    
    if (errorString.contains('unauthenticated')) {
      return 'Please sign in to continue.';
    }
    
    // Stock errors
    if (errorString.contains('insufficient stock')) {
      return error.toString().replaceFirst('Exception:', '').trim();
    }
    
    if (errorString.contains('no longer exists')) {
      return error.toString().replaceFirst('Exception:', '').trim();
    }
    
    // Product errors
    if (errorString.contains('barcode')) {
      return 'Product not found. Please scan again or enter manually.';
    }
    
    // Receipt errors
    if (errorString.contains('already been verified')) {
      return 'This receipt has already been verified.';
    }
    
    if (errorString.contains('receipt not found')) {
      return 'Receipt not found. It may have been deleted.';
    }
    
    // Auth errors
    if (errorString.contains('wrong-password') || 
        errorString.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    
    if (errorString.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    
    if (errorString.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    
    if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password.';
    }
    
    if (errorString.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    
    // Default friendly message
    return 'Something went wrong. Please try again.';
  }
  
  /// Get specific message for product operations
  static String getProductErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('barcode')) {
      return 'Invalid or duplicate barcode.';
    }
    
    if (errorString.contains('sku')) {
      return 'Invalid or duplicate SKU.';
    }
    
    return getFriendlyMessage(error);
  }
  
  /// Get specific message for checkout operations
  static String getCheckoutErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('stock')) {
      return error.toString().replaceFirst('Exception:', '').trim();
    }
    
    if (errorString.contains('payment')) {
      return 'Payment failed. Please try again.';
    }
    
    return getFriendlyMessage(error);
  }
  
  /// Get specific message for user operations
  static String getUserErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('email')) {
      return 'Invalid email address.';
    }
    
    if (errorString.contains('role')) {
      return 'Invalid user role.';
    }
    
    return getFriendlyMessage(error);
  }
}
