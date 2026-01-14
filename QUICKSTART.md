# QuickBill - Quick Start Guide

Get your QuickBill app running in 5 minutes!

## Step 1: Install Dependencies
```bash
cd /Users/rohitranjan/Documents/personal/quickbill
flutter pub get
```

## Step 2: Firebase Setup (Essential)

### Option A: Using FlutterFire CLI (Recommended)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (follow the prompts)
flutterfire configure
```

This automatically:
- Creates/connects Firebase project
- Generates `firebase_options.dart`
- Downloads platform-specific config files

### Option B: Manual Setup
1. Go to https://console.firebase.google.com/
2. Create new project "QuickBill"
3. Add Android/iOS app
4. Download config files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

## Step 3: Enable Firebase Services

In Firebase Console:

1. **Authentication**
   - Go to: Build → Authentication → Sign-in method
   - Click "Google" → Enable → Save

2. **Firestore Database**
   - Go to: Build → Firestore Database
   - Click "Create database"
   - Select "Start in test mode"
   - Choose region → Enable

## Step 4: Add SHA-1 for Google Sign-In (Android Only)

```bash
# Get SHA-1 fingerprint
cd android
./gradlew signingReport

# Copy the SHA1 fingerprint from output
# Example: SHA1: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
```

Add to Firebase:
- Firebase Console → Project Settings
- Your Apps → Android app
- Add fingerprint → Paste SHA1 → Save

## Step 5: Add Test Products to Firestore

Go to Firestore Console and create:

**Collection:** `products`

**Document 1:**
- Document ID: `1234567890123`
- Fields:
  ```
  barcode: "1234567890123"
  name: "Sample Milk 1L"
  price: 65
  category: "Dairy"
  imageUrl: ""
  ```

**Document 2:**
- Document ID: `9876543210987`
- Fields:
  ```
  barcode: "9876543210987"
  name: "Bread Loaf"
  price: 35
  category: "Bakery"
  imageUrl: ""
  ```

## Step 6: Run the App

```bash
# Check connected devices
flutter devices

# Run on Android
flutter run

# Run on iOS (Mac only)
flutter run -d ios

# Run on Chrome (for testing UI)
flutter run -d chrome
```

## Testing Workflow

1. **Launch App** → See Google Sign-In screen
2. **Sign In** → Tap "Sign in with Google" → Choose account
3. **Home Screen** → Tap "Start Scanning"
4. **Scan** → Point camera at barcode `1234567890123` or `9876543210987`
5. **Cart** → Tap cart icon → See scanned items
6. **Checkout** → Tap "Proceed to Checkout" → Select payment → Pay
7. **Receipt** → View QR code receipt
8. **Done** → Tap "Done" to return home

## Common Issues & Fixes

### ❌ "Google Sign-In failed"
**Fix:** Add SHA-1 fingerprint to Firebase Console

### ❌ "Product not found"
**Fix:** Add sample products to Firestore (Step 5)

### ❌ "Camera permission denied"
**Fix:** Go to phone Settings → Apps → QuickBill → Permissions → Enable Camera

### ❌ Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### ❌ "Firebase not configured"
**Fix:** Run `flutterfire configure` again

## Next Steps

- Add more products to Firestore
- Test on physical device for better camera performance
- Customize UI colors and branding
- Set up production Firebase security rules

## Test Barcodes

Use these barcodes for testing (or create your own):
- `1234567890123` - Sample Milk
- `9876543210987` - Bread
- Any 13-digit number (add to Firestore first)

## Need Help?

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed documentation.

---

🎉 **You're all set!** Enjoy building with QuickBill!
