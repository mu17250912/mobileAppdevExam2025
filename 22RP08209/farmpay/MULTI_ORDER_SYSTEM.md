# Multi-Order Payment System

## Overview
The FarmPay app now supports a multi-order payment system where users can:
1. Create multiple orders from their cart
2. View all pending orders
3. Select which orders to pay for
4. Pay for selected orders individually

## Key Features

### 1. Order Creation
- Users can add items to cart and create orders
- Orders are stored with status "pending"
- Cart is cleared after order creation
- Users can create multiple orders without immediate payment

### 2. Order Selection Screen
- View all pending orders for the user
- Select/deselect orders using checkboxes
- See order details including items and amounts
- "Select All" and "Clear" options for bulk selection
- Total amount calculation for selected orders

### 3. Payment System
- Users can choose between calculated total or custom amount
- Multiple payment methods (Mobile Money, Bank Transfer, Cash on Delivery)
- Real-time payment amount updates
- Payment status tracking

## User Flow

1. **Browse Products** → Add items to cart
2. **Create Order** → Cart items become a pending order
3. **View Pending Orders** → See all orders that need payment
4. **Select Orders** → Choose which orders to pay for
5. **Payment** → Pay for selected orders with flexible amounts

## Database Structure

### Orders Collection
```json
{
  "id": "order_id",
  "userId": "user_id",
  "items": [
    {
      "productId": "product_id",
      "name": "Product Name",
      "price": 2500.0,
      "quantity": 2
    }
  ],
  "total": 5000.0,
  "currency": "RWF",
  "status": "pending",
  "created_at": "2024-01-01T00:00:00Z",
  "payment_amount": 5000.0,
  "payment_method": "Mobile Money",
  "payment_status": "paid",
  "paid_at": "2024-01-01T00:00:00Z"
}
```

## Screens

### Cart Screen
- Shows cart items with quantities
- "Create Order" button to create pending order
- "View Pending Orders" button to see all orders

### Order Selection Screen
- Lists all pending orders
- Checkbox selection for each order
- Bulk selection controls
- Total amount for selected orders
- "Pay Selected Orders" button

### Payment Screen
- Order summary with items
- Flexible payment amount (calculated or custom)
- Multiple payment methods
- Real-time amount updates

## Future Enhancements

1. **Bulk Payment**: Pay for multiple orders in one transaction
2. **Order Splitting**: Split large orders into smaller payments
3. **Payment Plans**: Installment payment options
4. **Order Modifications**: Edit orders before payment
5. **Payment History**: Detailed payment tracking

## Testing

To test the system:
1. Add products to cart
2. Create multiple orders
3. Go to "Pay Orders" section
4. Select orders to pay for
5. Complete payment process

The system ensures users can manage multiple orders efficiently while maintaining flexibility in payment amounts and methods. 