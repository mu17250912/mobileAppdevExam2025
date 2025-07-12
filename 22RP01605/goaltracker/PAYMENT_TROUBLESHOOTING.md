# Payment Troubleshooting Guide

## Why Payment is Not Processing

### 1. **API Endpoint Issues** ✅ FIXED
**Problem**: The LnPay service was using incorrect API endpoints.
**Solution**: Updated to use the same endpoints as the working proxy code.

### 2. **Network Connectivity** 🔍 CHECK
**Symptoms**: 
- "Network error" messages
- Timeout errors
- No response from API

**Solutions**:
- Check internet connection
- Verify API endpoints are accessible
- Test with API test button (blue button in debug mode)

### 3. **API Key Issues** 🔍 CHECK
**Symptoms**:
- 401 Unauthorized errors
- "Invalid API key" messages

**Current API Key**: `6949156a26cafc9d148b0e36158bb005af91b67160f892ed9592cc595eaa818c`

**Solutions**:
- Verify API key is correct
- Check if API key has expired
- Contact API provider for new key

### 4. **Phone Number Format** 🔍 CHECK
**Symptoms**:
- "Invalid phone number" errors
- Payment not initiated

**Required Format**: 
- Must start with country code (e.g., 07 for Rwanda)
- Minimum 10 digits
- No special characters

**Example**: `0712345678`

### 5. **Response Parsing Issues** ✅ IMPROVED
**Problem**: API response format might not match expected format.
**Solution**: Enhanced response parsing with multiple fallback methods.

## Debugging Steps

### Step 1: Test API Connection
1. Run app in debug mode
2. Go to Profile screen
3. Click "Test: API Connection" (blue button)
4. Check console logs for API responses

### Step 2: Check Console Logs
Look for these log prefixes:
- `[LnPay]` - API request/response logs
- `[PaymentTracker]` - Payment processing logs
- `[ProfileScreen]` - UI interaction logs

### Step 3: Verify Payment Flow
1. Enter valid phone number
2. Click "Upgrade to Premium"
3. Check console for payment initiation logs
4. Monitor payment status updates

## Common Error Messages

### "Network error: SocketException"
**Cause**: No internet connection or API server down
**Solution**: Check internet connection and try again

### "Payment request failed: 401"
**Cause**: Invalid or expired API key
**Solution**: Update API key or contact provider

### "No transaction ID received"
**Cause**: API response format doesn't match expected format
**Solution**: Check API response format and update parsing logic

### "Payment polling timeout"
**Cause**: Payment verification taking too long
**Solution**: Check if payment was actually completed manually

## Testing the Payment System

### 1. API Test (Recommended First Step)
```dart
// Use the blue "Test: API Connection" button
await ApiTest.testPaymentApi();
await ApiTest.testVerifyApi();
```

### 2. Simulate Payment Success
```dart
// Use the orange "Test: Simulate Payment Success" button
await _paymentTracker.simulateSuccessfulPayment(phone);
```

### 3. Manual Premium Upgrade
```dart
// For testing premium features
await _paymentTracker.testUpgradeToPremium();
```

## Expected API Responses

### Successful Payment Request
```json
{
  "status": 200,
  "response": {
    "success": true,
    "transactionId": "txn_123456",
    "message": "Payment initiated successfully"
  }
}
```

### Processing Payment
```json
{
  "status": 200,
  "response": {
    "transactionId": "txn_123456",
    "status": "processing",
    "message": "Payment is being processed"
  }
}
```

### Failed Payment
```json
{
  "status": 400,
  "response": {
    "error": "Invalid phone number",
    "message": "Please provide a valid phone number"
  }
}
```

## Firestore Collections

### Payments Collection
```javascript
{
  "uid": "user_id",
  "amount": 10000,
  "phone": "0712345678",
  "network": "mtn",
  "status": "processing|completed|failed|timeout",
  "transactionId": "txn_123456",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "errorMessage": "error details if failed"
}
```

### Users Collection
```javascript
{
  "uid": "user_id",
  "premium": true|false,
  "premiumUpgradedAt": "timestamp",
  // ... other user fields
}
```

## Manual Verification Steps

### 1. Check Firestore
- Verify payment record was created
- Check payment status field
- Look for error messages

### 2. Check Console Logs
- Look for `[PaymentTracker]` logs
- Check for API response logs
- Verify error messages

### 3. Test API Directly
```bash
curl -X POST https://www.lanari.rw/pay/lnpay/pay_proxy.php \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 10000,
    "phone": "0712345678",
    "network": "mtn",
    "apiKey": "6949156a26cafc9d148b0e36158bb005af91b67160f892ed9592cc595eaa818c"
  }'
```

## Quick Fixes

### If API is Down
1. Use test buttons to simulate payments
2. Manually upgrade users to premium for testing
3. Contact API provider for status

### If Response Format Changed
1. Update response parsing in `payment_tracker.dart`
2. Add new response format handling
3. Test with API test button

### If Auto-Upgrade Not Working
1. Check if payment status is 'completed'
2. Verify `_upgradeToPremium()` method is called
3. Check Firestore user document for premium field

## Contact Information

For API issues:
- Provider: Lanari Rwanda
- Endpoint: https://www.lanari.rw/pay/lnpay/
- Support: Contact API provider for technical support

For app issues:
- Check console logs for detailed error messages
- Use test buttons to isolate problems
- Verify Firestore permissions and rules 