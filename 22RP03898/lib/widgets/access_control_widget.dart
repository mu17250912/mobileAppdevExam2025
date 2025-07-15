import 'package:flutter/material.dart';
import 'package:saferide/models/user_model.dart';
import 'package:saferide/services/role_service.dart';
import 'package:saferide/services/auth_service.dart';

class AccessControlWidget extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallbackWidget;
  final String? customMessage;

  const AccessControlWidget({
    super.key,
    required this.permission,
    required this.child,
    this.fallbackWidget,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: RoleService().hasPermission(permission),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasPermission = snapshot.data ?? false;

        if (hasPermission) {
          return child;
        }

        return _buildAccessDeniedWidget(
          customMessage ?? 'You do not have permission to access this feature',
        );
      },
    );
  }

  Widget _buildAccessDeniedWidget(String message) {
    if (fallbackWidget != null) {
      return fallbackWidget!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.orange.shade600,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Access Restricted',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class RoleBasedWidget extends StatelessWidget {
  final Widget Function(UserType userType) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const RoleBasedWidget({
    super.key,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: AuthService().getCurrentUserModel(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return errorWidget ??
              Center(
                child: Text('Error: ${snapshot.error}'),
              );
        }

        final userModel = snapshot.data;
        if (userModel == null) {
          return errorWidget ??
              const Center(
                child: Text('User not found'),
              );
        }

        return builder(userModel.userType);
      },
    );
  }
}

class AdminOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;
  final String? customMessage;

  const AdminOnlyWidget({
    super.key,
    required this.child,
    this.fallbackWidget,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: RoleService().isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final isAdmin = snapshot.data ?? false;

        if (isAdmin) {
          return child;
        }

        return fallbackWidget ??
            _buildAccessDeniedWidget(
              customMessage ?? 'Admin access required',
            );
      },
    );
  }

  Widget _buildAccessDeniedWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.admin_panel_settings,
            color: Colors.red.shade600,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Admin Access Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class DriverOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;
  final String? customMessage;

  const DriverOnlyWidget({
    super.key,
    required this.child,
    this.fallbackWidget,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: RoleService().isDriver(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final isDriver = snapshot.data ?? false;

        if (isDriver) {
          return child;
        }

        return fallbackWidget ??
            _buildAccessDeniedWidget(
              customMessage ?? 'Driver access required',
            );
      },
    );
  }

  Widget _buildAccessDeniedWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_car,
            color: Colors.blue.shade600,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Driver Access Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class PassengerOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;
  final String? customMessage;

  const PassengerOnlyWidget({
    super.key,
    required this.child,
    this.fallbackWidget,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: RoleService().isPassenger(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final isPassenger = snapshot.data ?? false;

        if (isPassenger) {
          return child;
        }

        return fallbackWidget ??
            _buildAccessDeniedWidget(
              customMessage ?? 'Passenger access required',
            );
      },
    );
  }

  Widget _buildAccessDeniedWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            color: Colors.green.shade600,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Passenger Access Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
