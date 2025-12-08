# Purchase Request Module

Complete Flutter module for creating purchase requests with Laravel API integration.

## Features

✅ All master data loaded in parallel on page load
✅ Shimmer loading effect while fetching data
✅ Dynamic item rows with add/remove functionality
✅ Complete form validation
✅ Bottom sheet for adding items
✅ Success/Error dialogs
✅ Sanctum authentication support

## Usage

### 1. Add Providers to Your App

```dart
import 'package:provider/provider.dart';
import 'providers/master_provider.dart';
import 'providers/purchase_request_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MasterProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseRequestProvider()),
        // ... your other providers
      ],
      child: MyApp(),
    ),
  );
}
```

### 2. Navigate to Purchase Request Screen

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PurchaseRequestCreateScreen(),
  ),
);
```

### 3. API Configuration

Make sure your `lib/config/app_config.dart` has the correct base URL:

```dart
static const String baseUrl = 'http://your-api-url.com/api';
```

## API Endpoints Used

### GET Endpoints (Master Data)
- `/api/meta/roles`
- `/api/meta/vendor-types`
- `/api/meta/purchase-modes`
- `/api/meta/priorities`
- `/api/meta/payment-options`
- `/api/items/types`
- `/api/items/gst-classes`
- `/api/items/statuses`
- `/api/suppliers`
- `/api/items`
- `/api/godowns`
- `/api/plants`

### POST Endpoint
- `/api/purchase-requests`

## Form Fields

### General Fields
- Vendor Type (required)
- Vendor/Supplier (required)
- Purchase Mode (required)
- Priority (required)
- Payment Option
- Select Site
- Required By Date
- Additional Notes

### Items Section
- Item (required)
- Item Type
- Godown
- Qty Required (required, > 0)
- Unit Price (required, > 0)
- GST Classification
- Status

## JSON Submission Format

```json
{
  "vendor_type": "string",
  "vendor_id": 3,
  "purchase_mode": "cash",
  "priority": "normal",
  "payment_option": "technician_wallet",
  "site_id": 12,
  "required_by_date": "2025-02-01",
  "notes": "something",
  "items": [
    {
      "item_id": 5,
      "qty_required": 2,
      "est_unit_price": 120,
      "item_type_id": 1,
      "godown_id": 2,
      "gst_classification_id": 3,
      "status_id": 1
    }
  ]
}
```

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  provider: ^6.1.1
  http: ^1.1.0
  shared_preferences: ^2.2.2
  shimmer: ^3.0.0
  intl: ^0.19.0
```

## File Structure

```
lib/
├── api/
│   ├── api_client.dart          # HTTP client with Sanctum auth
│   ├── master_api.dart          # All GET endpoints
│   └── purchase_api.dart        # POST endpoint
├── models/
│   ├── dropdown_model.dart      # Generic dropdown model
│   ├── supplier_model.dart      # Supplier model
│   ├── item_model.dart          # Item model
│   └── purchase_item_model.dart # Purchase item model
├── providers/
│   ├── master_provider.dart     # Master data state
│   └── purchase_request_provider.dart # Form state
├── widgets/
│   ├── dropdown_field.dart     # Custom dropdown widget
│   ├── item_row_widget.dart    # Item row widget
│   └── shimmer_loader.dart     # Loading shimmer
└── screens/purchase/
    └── purchase_request_create.dart # Main form screen
```

## Error Handling

- Network errors are caught and displayed
- Validation errors show specific field messages
- API errors are shown in dialogs
- Loading states prevent multiple submissions

## Notes

- All master data is loaded in parallel for better performance
- Form state is managed using Provider
- Token is automatically included in all requests via ApiClient
- Form validation ensures data integrity before submission









