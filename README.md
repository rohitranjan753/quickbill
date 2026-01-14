# QuickBill - Smart Grocery Billing App

A professional Flutter application for quick grocery store billing with barcode scanning, Google authentication, and digital receipts.

## 🚀 Features

### User Features
- ✅ **Google Sign-In** - Secure authentication with Google account
- ✅ **User Profile** - Name and photo stored in Cloud Firestore
- ✅ **Barcode Scanner** - Scan product barcodes/QR codes using device camera
- ✅ **Shopping Cart** - Add, remove, and manage items with quantity control
- ✅ **Digital Receipts** - Get QR code receipts after checkout
- ✅ **Receipt History** - View all past purchases
- ✅ **Exit Verification** - Show QR code at exit for guard verification

### Technical Features
- 🏗️ **BLoC Architecture** - Clean, testable state management
- 🔥 **Firebase Backend** - Authentication, Firestore, and cloud storage
- 📱 **Material Design 3** - Modern, responsive UI
- 🎯 **Best Practices** - Following Flutter and Firebase best practices

## 📋 Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / Xcode for mobile development
- Firebase account
- Google Cloud Console access

## 🛠️ Installation

### 1. Clone and Setup
```bash
cd /Users/rohitranjan/Documents/personal/quickbill
flutter pub get
```

### 2. Firebase Configuration

#### Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

#### Configure Firebase
```bash
flutterfire configure
```

This will:
- Create a Firebase project (or use existing one)
- Register your Flutter app with Firebase
- Generate `firebase_options.dart` with your credentials
- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

### 3. Enable Firebase Services

Go to [Firebase Console](https://console.firebase.google.com/):

1. **Authentication**
   - Navigate to Authentication → Sign-in method
   - Enable "Google" provider
   - Add support email

2. **Firestore Database**
   - Navigate to Firestore Database
   - Click "Create database"
   - Start in test mode (for development)
   - Select your preferred region

### 4. Google Sign-In Setup

#### For Android:
1. Get your SHA-1 fingerprint:
```bash
cd android
./gradlew signingReport
```

2. Add SHA-1 to Firebase:
   - Go to Project Settings → Your Apps → Android
   - Add SHA-1 certificate fingerprint

#### For iOS:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Update the Bundle Identifier if needed
3. Download `GoogleService-Info.plist` from Firebase
4. Add it to `ios/Runner/` in Xcode

### 5. Add Sample Products (Testing)

Add sample products to Firestore for testing:

**Collection: `products`**

Document ID: `1234567890123`
```json
{
  "barcode": "1234567890123",
  "name": "Milk 1L",
  "price": 65.00,
  "category": "Dairy",
  "imageUrl": ""
}
```

Document ID: `9876543210987`
```json
{
  "barcode": "9876543210987",
  "name": "Bread",
  "price": 35.00,
  "category": "Bakery",
  "imageUrl": ""
}
```

### 6. Run the App

```bash
# Run on Android
flutter run

# Run on iOS
flutter run -d ios

# Build for release
flutter build apk  # Android
flutter build ios  # iOS
```

## 📱 How to Use

1. **Sign In**
   - Open the app
   - Tap "Sign in with Google"
   - Select your Google account
   - Grant permissions

2. **Scan Products**
   - Tap "Start Scanning" on home screen
   - Point camera at product barcode
   - Product automatically adds to cart
   - Continue scanning more products

3. **Manage Cart**
   - Tap cart icon to view items
   - Adjust quantities with +/- buttons
   - Remove items if needed
   - View total amount

4. **Checkout**
   - Tap "Proceed to Checkout"
   - Select payment method (UPI/Card/Cash)
   - Tap "Pay" to complete

5. **View Receipt**
   - Digital receipt with QR code generated
   - Show QR code at exit to guard
   - Access past receipts from menu

## 🏗️ Project Structure

```
lib/
├── blocs/
│   ├── auth/
│   │   ├── auth_bloc.dart
│   │   ├── auth_event.dart
│   │   └── auth_state.dart
│   └── cart/
│       ├── cart_bloc.dart
│       ├── cart_event.dart
│       └── cart_state.dart
├── models/
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── cart_item_model.dart
│   └── receipt_model.dart
├── screens/
│   ├── sign_in_screen.dart
│   ├── home_screen.dart
│   ├── scanner_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── receipt_screen.dart
│   └── receipts_screen.dart
├── services/
│   ├── auth_service.dart
│   └── firestore_service.dart
├── firebase_options.dart
└── main.dart
```

## 🔒 Firestore Security Rules

For production, update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only
    }
    
    match /receipts/{receiptId} {
      allow read: if request.auth != null && 
                     resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid;
      allow update: if request.auth != null && 
                       resource.data.userId == request.auth.uid;
    }
  }
}
```

## 📊 Database Schema

### Users Collection
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "photoURL": "string (optional)",
  "createdAt": "timestamp",
  "lastLogin": "timestamp"
}
```

### Products Collection
```json
{
  "barcode": "string",
  "name": "string",
  "price": "number",
  "category": "string",
  "imageUrl": "string (optional)"
}
```

### Receipts Collection
```json
{
  "id": "string",
  "userId": "string",
  "items": [
    {
      "product": { /* product object */ },
      "quantity": "number"
    }
  ],
  "totalAmount": "number",
  "purchaseDate": "timestamp",
  "paymentMethod": "string",
  "verified": "boolean"
}
```

## 🔧 Troubleshooting

### Google Sign-In Issues
- Verify SHA-1 fingerprint is added to Firebase Console
- Check `google-services.json` is in `android/app/`
- Ensure Google Sign-In is enabled in Firebase Console

### Camera Not Working
- Grant camera permissions when prompted
- Check permissions in `AndroidManifest.xml` and `Info.plist`
- Test on physical device (emulator cameras can be unreliable)

### Product Not Found
- Add products to Firestore with correct barcode as document ID
- Verify barcode format (usually 13 digits for EAN-13)
- Check Firestore security rules allow reading products

### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ios && pod deintegrate && pod install
flutter run
```

## 🚀 Future Enhancements

- [ ] Admin panel for product management
- [ ] Receipt verification scanner for guards
- [ ] Offline mode with local database sync
- [ ] Payment gateway integration (Razorpay/Stripe)
- [ ] Promotional offers and discounts
- [ ] Analytics dashboard
- [ ] Push notifications for offers
- [ ] Multiple store support
- [ ] Inventory management

## 📄 License

This project is created for educational and commercial purposes.

## 👨‍💻 Author

Created with ❤️ using Flutter and Firebase

## 📞 Support

For detailed setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md)
