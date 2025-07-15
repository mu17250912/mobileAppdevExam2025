import 'package:flutter_test/flutter_test.dart';
import 'package:budgetwise/services/analytics_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Generate mocks
@GenerateMocks([FirebaseFirestore, FirebaseAuth, User, QuerySnapshot, QueryDocumentSnapshot])
import 'analytics_service_test.mocks.dart';

void main() {
  group('AnalyticsService Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockQuerySnapshot mockQuerySnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockQuerySnapshot = MockQuerySnapshot();
    });

    group('getSpendingByCategory', () {
      test('should return empty map when user is not logged in', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = await AnalyticsService.getSpendingByCategory(1, 2024);

        // Assert
        expect(result, isEmpty);
      });

      test('should aggregate expenses by category correctly', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-user-id');

        final mockDocs = [
          MockQueryDocumentSnapshot(),
          MockQueryDocumentSnapshot(),
        ];

        when(mockDocs[0].data()).thenReturn({
          'category': 'Food',
          'amount': 100.0,
        });
        when(mockDocs[1].data()).thenReturn({
          'category': 'Food',
          'amount': 50.0,
        });

        when(mockQuerySnapshot.docs).thenReturn(mockDocs);
        when(mockFirestore
            .collection('expenses')
            .doc('test-user-id')
            .collection('user_expenses')
            .where('month', isEqualTo: 1)
            .where('year', isEqualTo: 2024)
            .get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await AnalyticsService.getSpendingByCategory(1, 2024);

        // Assert
        expect(result['Food'], equals(150.0));
      });
    });

    group('getMonthlyTrends', () {
      test('should return empty list when user is not logged in', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = await AnalyticsService.getMonthlyTrends();

        // Assert
        expect(result, isEmpty);
      });

      test('should return trends for last 6 months', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-user-id');

        final mockDocs = [MockQueryDocumentSnapshot()];
        when(mockDocs[0].data()).thenReturn({'amount': 100.0});
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Mock multiple queries for different months
        when(mockFirestore
            .collection('expenses')
            .doc('test-user-id')
            .collection('user_expenses')
            .where('month', isEqualTo: anyNamed('isEqualTo'))
            .where('year', isEqualTo: anyNamed('isEqualTo'))
            .get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await AnalyticsService.getMonthlyTrends();

        // Assert
        expect(result.length, equals(6));
      });
    });

    group('getBudgetVsActual', () {
      test('should return empty map when user is not logged in', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = await AnalyticsService.getBudgetVsActual(1, 2024);

        // Assert
        expect(result, isEmpty);
      });

      test('should calculate budget vs actual correctly', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-user-id');

        final mockBudgetDocs = [MockQueryDocumentSnapshot()];
        final mockExpenseDocs = [MockQueryDocumentSnapshot()];

        when(mockBudgetDocs[0].data()).thenReturn({
          'amount': 1000.0,
        });
        when(mockExpenseDocs[0].data()).thenReturn({
          'amount': 750.0,
        });

        final mockBudgetSnapshot = MockQuerySnapshot();
        final mockExpenseSnapshot = MockQuerySnapshot();

        when(mockBudgetSnapshot.docs).thenReturn(mockBudgetDocs);
        when(mockExpenseSnapshot.docs).thenReturn(mockExpenseDocs);

        // Mock budget query
        when(mockFirestore
            .collection('budgets')
            .doc('test-user-id')
            .collection('user_budgets')
            .where('month', isEqualTo: 1)
            .where('year', isEqualTo: 2024)
            .get()).thenAnswer((_) async => mockBudgetSnapshot);

        // Mock expense query
        when(mockFirestore
            .collection('expenses')
            .doc('test-user-id')
            .collection('user_expenses')
            .where('month', isEqualTo: 1)
            .where('year', isEqualTo: 2024)
            .get()).thenAnswer((_) async => mockExpenseSnapshot);

        // Act
        final result = await AnalyticsService.getBudgetVsActual(1, 2024);

        // Assert
        expect(result['budget'], equals(1000.0));
        expect(result['actual'], equals(750.0));
        expect(result['remaining'], equals(250.0));
        expect(result['percentage'], equals(75.0));
      });
    });
  });
} 