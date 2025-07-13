// Conditional export for platform-specific payment slip service
export 'payment_slip_service_io.dart' if (dart.library.html) 'payment_slip_service_web.dart'; 