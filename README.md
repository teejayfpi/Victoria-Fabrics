# 🧵 Fabric Haven - Nigerian Fabrics Store App

A modern Flutter mobile application for a Nigerian fabrics retail and delivery business. Customers can browse fabrics (Ankara, Lace, Cotton, Silk, etc.), select measurement units, add items to cart, and checkout with Delivery or Pickup options.

## ✨ Features

### Customer App
- 🛍️ **Product Browsing** - Browse fabrics by categories (Ankara, Lace, Cotton, Silk, Voile, Chiffon)
- 📏 **Measurement Units** - Select quantity in Yards, Meters, or Pieces
- 🔍 **Search & Filter** - Search by fabric name, filter by category and price
- 📦 **Product Details** - View fabric details with images, description, colors
- 🛒 **Shopping Cart** - Add/remove items, update quantities, view totals
- 🚚 **Checkout** - Choose Delivery or Pickup, enter delivery address
- 📋 **Order History** - View past orders and their status

### Admin Panel
- 📊 **Dashboard** - Overview of sales, orders, and key metrics
- 📦 **Product Management** - Add, edit, delete products
- 🏷️ **Category Management** - Manage fabric categories
- 📦 **Order Management** - View and update order status
- 📈 **Analytics** - Sales reports and insights

## 🏗️ Architecture

This app follows **Clean Architecture** principles:

```
lib/
├── core/
│   ├── constants/       # App-wide constants and enums
│   ├── error/           # Custom exceptions and Result types
│   └── theme/           # App theming (Material 3)
├── data/
│   └── datasources/     # Data sources (mock/Firebase)
├── domain/
│   └── entities/        # Business entities (Product, Order, etc.)
├── presentation/
│   ├── providers/       # Riverpod state providers
│   ├── router/          # go_router navigation
│   ├── screens/         # UI screens
│   └── widgets/         # Reusable widgets
├── admin/               # Admin panel
│   ├── providers/       # Admin state management
│   ├── router/          # Admin navigation
│   └── screens/         # Admin UI screens
└── main.dart            # App entry point
```

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.24.0 |
| Language | Dart 3.5.0 |
| State Management | Riverpod (flutter_riverpod) |
| Navigation | go_router |
| Backend | Firebase (Firestore, Auth) |
| Architecture | Clean Architecture |
| Design System | Material Design 3 |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.24.0+
- Dart 3.5.0+
- Android SDK (for Android builds)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/coopvestafrica-ops/Victoria-Fabrics.git
cd Victoria-Fabrics/fabric_haven
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app (Demo Mode)**
```bash
flutter run
```
The app runs immediately in demo mode with mock data - no Firebase setup required!

4. **Connect Firebase (Production)**
```bash
# Create a Firebase project at https://console.firebase.google.com
flutterfire configure
flutter run
```

### Building

**Debug APK:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter build apk --release
```

**iOS (requires macOS):**
```bash
flutter build ios
```

## 📱 App Screens

### Customer App Screens
| Screen | Description |
|--------|-------------|
| Home | Featured products, categories, search |
| Categories | All fabric categories |
| Category Products | Products filtered by category |
| Product Detail | Full product info, add to cart |
| Cart | Shopping cart management |
| Checkout | Delivery/pickup selection |
| Order Confirmation | Success message, order ID |
| Orders | Order history with status |
| Profile | User info, settings |

### Admin Panel Screens
| Screen | Description |
|--------|-------------|
| Login | Admin authentication |
| Dashboard | Stats overview, recent orders |
| Products | Product list with search/filter |
| Add/Edit Product | Product form |
| Orders | Order list with status tabs |
| Categories | Category management |
| Analytics | Sales reports, charts |

## 🧪 Testing

Run tests:
```bash
flutter test
```

## 📦 Demo Mode

The app includes a comprehensive demo mode that works without Firebase:

- **12 sample products** across 6 categories
- **Mock cart and order management**
- **Simulated admin functionality**
- Console logs indicate demo mode: `[Fabric Haven] Running in demo mode with mock data.`

## 🔥 Firebase Setup (Production)

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Enable Firestore Database
4. Run `flutterfire configure`
5. Update `lib/data/datasources/` to use Firestore

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- **Fabric Haven Team** - Initial work

## 🙏 Acknowledgments

- Inspired by [Abeni Mart](https://github.com/coopvestafrica-ops/Abeni-) by Coopvest Africa
- Nigerian measurement system (Congo, Yard, Meter, Piece)
- Material Design 3 components

---

Made with ❤️ for the Nigerian fabric market