import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/guards/pending_action.dart';

void main() {
  group('PendingAction Model & Notifier Tests', () {
    test('captures and retains variant and quantity intent payload', () {
      final notifier = PendingActionNotifier();
      expect(notifier.state, isNull);

      const action = PendingAction(
        type: PendingActionType.addToCart,
        productId: 'prod_uniform_set',
        variantId: 'size_34_boys',
        quantity: 2,
        extraPayload: {'school': "St. Xavier's"},
      );

      notifier.setPendingAction(action);
      expect(notifier.state, isNotNull);
      expect(notifier.state?.type, equals(PendingActionType.addToCart));
      expect(notifier.state?.productId, equals('prod_uniform_set'));
      expect(notifier.state?.variantId, equals('size_34_boys'));
      expect(notifier.state?.quantity, equals(2));
      expect(notifier.state?.extraPayload?['school'], equals("St. Xavier's"));
    });

    test('consumePendingAction atomically returns action and resets state to null', () {
      final notifier = PendingActionNotifier();
      const action = PendingAction(
        type: PendingActionType.buyNow,
        productId: 'prod_book_bundle_6',
      );

      notifier.setPendingAction(action);
      expect(notifier.state, isNotNull);

      final consumed = notifier.consumePendingAction();
      expect(consumed, equals(action));
      expect(notifier.state, isNull);
    });

    test('clear resets state without returning value', () {
      final notifier = PendingActionNotifier();
      notifier.setPendingAction(
        const PendingAction(type: PendingActionType.openOrders),
      );
      expect(notifier.state, isNotNull);

      notifier.clear();
      expect(notifier.state, isNull);
    });

    test('executes onExecute callback attached to pending action', () {
      bool executed = false;
      final action = PendingAction(
        type: PendingActionType.addToCart,
        productId: 'item_1',
        onExecute: () => executed = true,
      );

      expect(executed, isFalse);
      action.onExecute?.call();
      expect(executed, isTrue);
    });
  });
}
