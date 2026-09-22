import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';

void main() {
  group('CartItemModel Domain Tests', () {
    const testItem = CartItemModel(
      productId: 'prod_101',
      variantId: 'v_28',
      productName: 'DPS Boys Navy Trouser',
      schoolName: 'Delhi Public School',
      variantLabel: 'Size: 28',
      imageUrl: 'https://cdn.bookvardi.com/trouser.png',
      unitPrice: 850.0,
      quantity: 2,
      maxStock: 5,
    );

    test('verifies all property getters, composite id, and calculations', () {
      expect(testItem.id, equals('prod_101_v_28'));
      expect(testItem.productId, equals('prod_101'));
      expect(testItem.variantId, equals('v_28'));
      expect(testItem.productName, equals('DPS Boys Navy Trouser'));
      expect(testItem.schoolName, equals('Delhi Public School'));
      expect(testItem.variantLabel, equals('Size: 28'));
      expect(testItem.imageUrl, equals('https://cdn.bookvardi.com/trouser.png'));
      expect(testItem.unitPrice, equals(850.0));
      expect(testItem.quantity, equals(2));
      expect(testItem.maxStock, equals(5));
      expect(testItem.totalPrice, equals(1700.0));
      expect(testItem.isAtMaxStock, isFalse);
    });

    test('composite id defaults to "default" when variantId is null', () {
      const itemWithoutVariant = CartItemModel(
        productId: 'prod_202',
        productName: 'Notebook Pack',
        unitPrice: 300.0,
      );
      expect(itemWithoutVariant.id, equals('prod_202_default'));
      expect(itemWithoutVariant.variantId, isNull);
      expect(itemWithoutVariant.totalPrice, equals(300.0));
      expect(itemWithoutVariant.isAtMaxStock, isFalse);
    });

    test('isAtMaxStock returns true when quantity equals or exceeds maxStock', () {
      final atMax = testItem.copyWith(quantity: 5);
      expect(atMax.isAtMaxStock, isTrue);

      final overMax = testItem.copyWith(quantity: 6);
      expect(overMax.isAtMaxStock, isTrue);
    });

    test('creates CartItemModel from ProductModel and VariantModel', () {
      const product = ProductModel(
        productId: 'prod_shirt',
        name: 'School White Shirt',
        description: 'Cotton uniform shirt',
        categoryId: 'cat_uniforms',
        schoolName: 'St. Xavier High School',
        basePrice: 500.0,
        discountPrice: 450.0,
        images: ['https://cdn.bookvardi.com/shirt.png'],
        totalStock: 20,
      );

      const variant = VariantModel(
        variantId: 'v_shirt_32',
        sku: 'SHIRT-32',
        label: 'Size 32',
        price: 480.0,
        stock: 8,
      );

      final cartItem = CartItemModel.fromProduct(
        product,
        variant: variant,
        quantity: 3,
      );

      expect(cartItem.id, equals('prod_shirt_v_shirt_32'));
      expect(cartItem.productId, equals('prod_shirt'));
      expect(cartItem.variantId, equals('v_shirt_32'));
      expect(cartItem.productName, equals('School White Shirt'));
      expect(cartItem.schoolName, equals('St. Xavier High School'));
      expect(cartItem.variantLabel, equals('Size 32'));
      expect(cartItem.imageUrl, equals('https://cdn.bookvardi.com/shirt.png'));
      expect(cartItem.unitPrice, equals(480.0));
      expect(cartItem.quantity, equals(3));
      expect(cartItem.maxStock, equals(8));
      expect(cartItem.totalPrice, equals(1440.0));
    });

    test('creates CartItemModel from ProductModel without variant', () {
      const product = ProductModel(
        productId: 'prod_bag',
        name: 'School Backpack',
        description: 'Ergonomic bag',
        categoryId: 'cat_bags',
        basePrice: 1200.0,
        discountPrice: 999.0,
        images: ['https://cdn.bookvardi.com/bag.png'],
        totalStock: 15,
      );

      final cartItem = CartItemModel.fromProduct(product);

      expect(cartItem.id, equals('prod_bag_default'));
      expect(cartItem.variantId, isNull);
      expect(cartItem.unitPrice, equals(999.0)); // Uses effective discounted price
      expect(cartItem.quantity, equals(1));
      expect(cartItem.maxStock, equals(15));
      expect(cartItem.totalPrice, equals(999.0));
    });

    test('copyWith updates specified fields only', () {
      final updated = testItem.copyWith(
        quantity: 4,
        unitPrice: 900.0,
      );

      expect(updated.quantity, equals(4));
      expect(updated.unitPrice, equals(900.0));
      expect(updated.totalPrice, equals(3600.0));
      expect(updated.productName, equals(testItem.productName));
      expect(updated.id, equals(testItem.id));
    });

    test('serialization toMap / fromMap and toJson / fromJson round-trips cleanly', () {
      final map = testItem.toMap();
      final fromMap = CartItemModel.fromMap(map);
      expect(fromMap, equals(testItem));

      final json = testItem.toJson();
      final fromJson = CartItemModel.fromJson(json);
      expect(fromJson, equals(testItem));
      expect(fromJson.hashCode, equals(testItem.hashCode));
    });

    test('value equality and toString', () {
      final clone = CartItemModel.fromMap(testItem.toMap());
      expect(clone, equals(testItem));
      expect(clone.hashCode, equals(testItem.hashCode));
      expect(testItem.toString(), contains('CartItemModel'));
      expect(testItem.toString(), contains('totalPrice: 1700.0'));
    });
  });
}
