import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:like/like.dart';

void main() {
  group('Like State Transition and Builder Tests', () {
    testWidgets('Idle state returns onIdle or empty widget', (WidgetTester tester) async {
      final response = LikeStateResponse<String>.idle();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LikeBuilder<String>(
              observe: () => response,
              onSuccess: (data, isRefreshing, isFromSWR) => Text('Success: $data'),
              onLoading: () => const Text('Loading...'),
              onIdle: () => const Text('Idle...'),
            ),
          ),
        ),
      );

      expect(find.text('Idle...'), findsOneWidget);
    });

    testWidgets('Loading state clears previous sticky data and returns onLoading', (WidgetTester tester) async {
      late StateSetter setTestState;
      var response = LikeStateResponse<String>.success('First Data');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setTestState = setState;
                return LikeBuilder<String>(
                  observe: () => response,
                  onSuccess: (data, isRefreshing, isFromSWR) => Text('Success: $data'),
                  onLoading: () => const Text('Loading...'),
                );
              },
            ),
          ),
        ),
      );

      // Verify success state initially rendered
      expect(find.text('Success: First Data'), findsOneWidget);

      // Transition to loading
      setTestState(() {
        response = LikeStateResponse<String>.loading();
      });
      await tester.pump();

      // Verify loading state is now shown instead of keeping the previous success data
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Success: First Data'), findsNothing);
    });

    testWidgets('Refreshing state preserves previous data and shows isRefreshing = true', (WidgetTester tester) async {
      late StateSetter setTestState;
      var response = LikeStateResponse<String>.success('Stale Data');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setTestState = setState;
                return LikeBuilder<String>(
                  observe: () => response,
                  onSuccess: (data, isRefreshing, isFromSWR) => Text(
                    'Success: $data, refreshing: $isRefreshing, swr: $isFromSWR',
                  ),
                  onLoading: () => const Text('Loading...'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Success: Stale Data, refreshing: false, swr: false'), findsOneWidget);

      // Transition to refreshing
      setTestState(() {
        response = LikeStateResponse<String>.refreshing('Stale Data');
      });
      await tester.pump();

      // Verify success callback is called with isRefreshing = true
      expect(find.text('Success: Stale Data, refreshing: true, swr: false'), findsOneWidget);
    });

    testWidgets('StaleWhileRevalidate state preserves cached data and shows isFromSWR = true', (WidgetTester tester) async {
      final response = LikeStateResponse<String>.staleWhileRevalidate('Cached Data');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LikeBuilder<String>(
              observe: () => response,
              onSuccess: (data, isRefreshing, isFromSWR) => Text(
                'Success: $data, refreshing: $isRefreshing, swr: $isFromSWR',
              ),
              onLoading: () => const Text('Loading...'),
            ),
          ),
        ),
      );

      expect(find.text('Success: Cached Data, refreshing: false, swr: true'), findsOneWidget);
    });

    testWidgets('Success state maps successfully to onSuccess', (WidgetTester tester) async {
      final response = LikeStateResponse<String>.success('Clean Data');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LikeBuilder<String>(
              observe: () => response,
              onSuccess: (data, isRefreshing, isFromSWR) => Text(
                'Success: $data, refreshing: $isRefreshing, swr: $isFromSWR',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Success: Clean Data, refreshing: false, swr: false'), findsOneWidget);
    });

    testWidgets('Error/Failure state maps correctly to onError', (WidgetTester tester) async {
      final response = LikeStateResponse<String>.error(
        LikeError(message: 'Request Failed', type: LikeApiErrorType.server),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LikeBuilder<String>(
              observe: () => response,
              onSuccess: (data, isRefreshing, isFromSWR) => Text('Success: $data'),
              onError: (error) => Text('Error: ${error.message}'),
            ),
          ),
        ),
      );

      expect(find.text('Error: Request Failed'), findsOneWidget);
    });

    testWidgets('Exception state maps correctly to onException', (WidgetTester tester) async {
      final response = LikeStateResponse<String>.exception('No Internet connection');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LikeBuilder<String>(
              observe: () => response,
              onSuccess: (data, isRefreshing, isFromSWR) => Text('Success: $data'),
              onException: (message) => Text('Exception: $message'),
            ),
          ),
        ),
      );

      expect(find.text('Exception: No Internet connection'), findsOneWidget);
    });

    test('toStateResponse maps SWR flag correctly to staleWhileRevalidate state', () {
      final swrResult = LikeApiResult<String>.success(
        'SWR Cache Data',
        isFromStaleWhileRevalidate: true,
      );

      final response = swrResult.toStateResponse();
      expect(response.state, LikeState.staleWhileRevalidate);
      expect(response.data, 'SWR Cache Data');
      expect(response.isFromStaleWhileRevalidate, isTrue);
    });
  });
}
