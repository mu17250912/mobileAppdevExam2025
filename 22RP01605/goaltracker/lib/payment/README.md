# Payment System Documentation

## Overview

The payment system in GoalTracker implements a comprehensive payment processing and verification system with automatic premium upgrade functionality.

## Components

### 1. LnPay Service (`lnpay_service.dart`)
Handles communication with the payment gateway API.

**Features:**
- Payment request initiation
- Payment status verification
- Payment completion checking
- Error handling and timeout management

**Methods:**
- `requestPayment(amount, phone, network)` - Initiates payment request
- `checkPaymentStatus(transactionId, phone)` - Checks payment status
- `verifyPayment(phone, amount, network)` - Verifies payment completion

### 2. Payment Tracker (`payment_tracker.dart`)
Manages payment lifecycle and automatic premium upgrades.

**Features:**
- Payment record creation and tracking
- Real-time payment status monitoring
- Automatic premium upgrade on successful payment
- Payment history management
- Polling mechanism for payment verification

**Key Methods:**
- `processPayment(amount, phone, network)` - Processes new payment
- `updatePaymentStatus(paymentId, status, transactionId, errorMessage)` - Updates payment status
- `_upgradeToPremium()` - Automatically upgrades user to premium
- `_pollPaymentStatus()` - Polls for payment completion

### 3. Profile Screen Integration
Enhanced profile screen with payment status display and management.

**Features:**
- Real-time payment status display
- Payment retry functionality
- Automatic profile refresh on payment completion
- Visual payment status indicators

## Payment Flow

1. **Payment Initiation**
   - User clicks "Upgrade to Premium"
   - Phone number validation
   - Payment record created in Firestore
   - Payment request sent to gateway

2. **Payment Processing**
   - Payment status tracked in real-time
   - Polling mechanism checks payment status every 30 seconds
   - Multiple verification methods (status check + payment verification)

3. **Payment Completion**
   - Payment status updated to "completed"
   - User automatically upgraded to premium
   - Profile refreshed to show premium status
   - Payment history updated

4. **Error Handling**
   - Failed payments marked with error details
   - Timeout handling (10 minutes max polling)
   - Retry functionality for failed payments

## Payment Statuses

- **pending**: Payment request created
- **processing**: Payment initiated, waiting for completion
- **completed**: Payment successful, user upgraded to premium
- **failed**: Payment failed with error details
- **timeout**: Payment verification timed out

## Auto-Upgrade Mechanism

When a payment is marked as "completed":
1. User's premium status is set to `true`
2. `premiumUpgradedAt` timestamp is recorded
3. Profile is automatically refreshed
4. UI updates to show premium features

## Security Features

- Payment records stored in Firestore with user isolation
- Transaction IDs tracked for verification
- Error messages logged for debugging
- Timeout protection against infinite polling

## Testing

Run payment system tests:
```bash
flutter test lib/payment/payment_test.dart
```

## API Endpoints

The system expects the following API endpoints:

- `POST /api/request_payment.php` - Initiate payment
- `POST /api/check_payment.php` - Check payment status
- `POST /api/verify_payment.php` - Verify payment completion

## Configuration

Update the API key in `payment_tracker.dart`:
```dart
final _lnPay = LnPay('your-api-key-here');
```

## Monitoring

Payment activities are logged with prefixes:
- `[PaymentTracker]` - Payment tracker operations
- `[ProfileScreen]` - Profile screen payment interactions

## Future Enhancements

1. Webhook support for real-time payment notifications
2. Multiple payment gateway support
3. Payment analytics and reporting
4. Subscription management for recurring payments
5. Payment receipt generation 