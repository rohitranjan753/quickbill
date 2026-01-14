# Multi-Role System Documentation

## Overview
The QuickBill app now supports three user roles with different views and capabilities:

### 1. **Customer** (Default Role)
- **View**: Shopping interface with barcode scanner
- **Features**:
  - Scan products to add to cart
  - View cart and checkout
  - View purchase receipts
  - Register as a store (role upgrade option)

### 2. **Store Admin**
- **View**: Store Dashboard with product management
- **Features**:
  - View all products in their store
  - Manage store inventory (Add/Edit/Delete products - Coming Soon)
  - View store statistics
  - Access store settings
  
### 3. **Guard**
- **View**: Receipt verification interface
- **Features**:
  - Scan customer receipts
  - Verify purchases at store exit
  - Security and verification dashboard

## How It Works

### User Registration Flow
1. Users sign in with Google (default role: Customer)
2. From the drawer menu, customers can tap "Register as Store"
3. Fill out the store registration form with:
   - Store name, description
   - Contact information (phone, email)
   - Address details (address, city, state, pincode)
   - Tax information (GST number - optional)
4. Upon submission:
   - Store is created in Firestore
   - User role is updated to "Store Admin"
   - User is linked to the store
   - Home screen automatically switches to Store Dashboard

### Role-Based Routing
The `HomeScreen` automatically routes users based on their role:
- **Customer** → Shopping interface with scanner
- **Store Admin** → Store Dashboard with product listing
- **Guard** → Receipt verification interface

## Database Structure

### Collections

#### `users`
```
{
  uid: string
  email: string
  displayName: string
  photoURL: string?
  role: "customer" | "storeAdmin" | "guard"
  storeId: string? (only for storeAdmin and guard)
  createdAt: timestamp
  lastLogin: timestamp
}
```

#### `stores`
```
{
  id: string
  owner_id: string (user uid)
  name: string
  description: string?
  logo: string?
  address: string
  city: string
  state: string
  pincode: string
  phone: string
  email: string?
  gst_number: string?
  is_active: boolean
  created_at: timestamp
  updated_at: timestamp
}
```

#### `products`
```
{
  id: string
  store_id: string
  ... (existing product fields)
}
```

## Key Files

### Models
- `lib/models/user_model.dart` - User with role and storeId
- `lib/models/store_model.dart` - Store information
- `lib/models/product_model.dart` - Product details (existing)

### Screens
- `lib/screens/home_screen.dart` - Role-based routing hub
- `lib/screens/register_store_screen.dart` - Store registration form
- `lib/screens/store_admin_home_screen.dart` - Store admin dashboard
- Customer screens (existing): scanner, cart, checkout, receipts

### Services
- `lib/services/firestore_service.dart` - Updated with:
  - Store CRUD operations
  - Product management by store
  - User role management

## Next Steps (TODO)

1. **Store Admin Features**:
   - Add Product screen
   - Edit Product screen
   - Store settings and profile
   - Sales analytics

2. **Guard Features**:
   - Receipt scanner implementation
   - Verification history
   - Real-time receipt validation

3. **Additional**:
   - Role change permissions
   - Multiple guards per store
   - Store branch management
