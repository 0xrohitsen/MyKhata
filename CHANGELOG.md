# Changelog

All notable changes to My Khata will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-27

### 🎉 Initial Release

This is the first stable release of My Khata - Simple Money Tracking app!

### ✨ Features Added

#### Authentication
- **Google Sign-In Integration** - Secure authentication using Firebase Auth
- **User Profile Management** - Automatic profile creation with Google account details
- **Account Deletion** - Complete data deletion support for privacy compliance

#### Customer Management
- **Add Customers** - Create customers with name, phone number, and notes
- **Customer Search** - Quick search functionality to find customers by name
- **Customer Details View** - Comprehensive view of each customer's transaction history
- **Delete Customers** - Remove customers with confirmation dialog

#### Transaction Management
- **Quick Transaction Entry** - Record "I Gave" and "I Got" transactions in under 5 seconds
- **Automatic Balance Calculation** - Real-time balance updates using atomic Firestore transactions
- **Transaction History** - View all transactions with timestamps and notes
- **Edit Transactions** - Modify existing transactions with automatic balance recalculation
- **Delete Transactions** - Remove transactions with balance adjustment

#### User Interface
- **Material 3 Design** - Modern, clean interface following Material You guidelines
- **Dark/Light Theme Support** - Full theme switching with system preference detection
- **Responsive Layout** - Optimized for various screen sizes
- **Intuitive Navigation** - Simple, user-friendly navigation patterns

#### Data & Sync
- **Offline-First Architecture** - Full functionality without internet connection
- **Automatic Cloud Sync** - Seamless synchronization when internet is available
- **Data Persistence** - Firestore offline persistence for reliable data storage
- **Cross-Device Sync** - Access your data from any device

#### Settings & Preferences
- **Theme Selection** - Choose between Light, Dark, or System default theme
- **Profile Information** - View Google account details
- **Sync Status** - Real-time sync status indicator
- **Privacy Controls** - Account and data deletion options

### 🛠️ Technical Implementation

#### Architecture
- **Clean Architecture** - Separation of concerns with data/domain/presentation layers
- **Riverpod State Management** - Reactive state management with dependency injection
- **Repository Pattern** - Abstracted data access with interface-based design

#### Backend
- **Firebase Authentication** - Secure Google Sign-In implementation
- **Cloud Firestore** - NoSQL database with offline persistence
- **Security Rules** - User-scoped data access controls
- **Atomic Transactions** - Consistent balance calculations

#### Performance
- **Optimized Balance Calculations** - Integer-based monetary storage (paise) to avoid floating-point errors
- **Efficient Queries** - Indexed Firestore queries for fast data retrieval
- **Lazy Loading** - On-demand data loading for better performance

### 🔒 Security & Privacy

- **End-to-End Encryption** - All data encrypted in transit using TLS
- **User Data Isolation** - Server-side security rules prevent cross-user data access
- **No Third-Party Sharing** - User data never shared with external services
- **GDPR Compliance** - Complete account and data deletion functionality

### 📱 Platform Support

- **Android 8.0+** - Minimum API level 26
- **Target SDK 35** - Latest Android features and security updates
- **Material 3** - Modern design language implementation

### 📊 Database Schema

```
users/{uid}/
├── profile/
└── customers/{customerId}/
    ├── customer_data
    └── transactions/{transactionId}/
```

### 🎯 Key Metrics

- **Transaction Speed** - Record transactions in under 5 seconds
- **Offline Support** - 100% functionality without internet
- **Balance Accuracy** - Atomic updates prevent calculation drift
- **User Privacy** - Zero third-party data sharing

### 📥 Download Information

- **APK Size** - 55.5MB
- **Installation Size** - ~80MB
- **Minimum RAM** - 2GB recommended
- **Storage** - 100MB available space

### 🔄 Migration Notes

This is the initial release, so no migration is required.

### 🐛 Known Limitations

- Android only (iOS support planned for v2.0)
- Single currency support (₹ INR only)
- No export functionality (planned for v2.0)
- No payment reminders (planned for v2.0)

### 👥 Contributors

- **Rohit Sen** ([@0xrohitsen](https://github.com/0xrohitsen)) - Initial development and architecture

---

## Version History

- **v1.0.0** - Initial stable release with core functionality
- **v0.x.x** - Development versions (not publicly released)

## Future Roadmap

### v1.1.0 (Minor Update)
- Bug fixes and performance improvements
- UI/UX refinements
- Enhanced error handling

### v2.0.0 (Major Update)
- iOS support
- PDF export functionality
- Multi-currency support
- Payment reminders
- Advanced reporting
- WhatsApp integration

---

For detailed technical documentation, see [README.md](README.md).
For contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).