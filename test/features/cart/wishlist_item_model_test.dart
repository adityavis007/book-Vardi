import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/cart/domain/wishlist_item_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';

void main() {
  group('WishlistItemModel Domain Tests', () {
    final fixedTime = DateTime(2026, 9, 18, 12, 0, 0);

    final testItem = WishlistItemModel(
      productId: 'prod_blazer_01',
      productName: 'DPS Winter Blazer',
      schoolName: 'Delhi Public School',
      imageUrl: 'https://cdn.bookvardi.com/blazer.png',
      price: 1600.0,
      mrp: 2000.0,
      inStock: true,
      addedAt: fixedTime,
    );

    test('verifies all getters and discount calculations', () {
      expect(testItem.productId, equals('prod_blazer_01'));
      expect(testItem.productName, equals('DPS Winter Blazer'));
      expect(testItem.schoolName, equals('Delhi Public School'));
      expect(testItem.imageUrl, equals('https://cdn.bookvardi.com/blazer.png'));
      expect(testItem.price, equals(1600.0));
      expect(testItem.mrp, equals(2000.0));
      expect(testItem.inStock, isTrue);
      expect(testItem.addedAt, equals(fixedTime));
      expect(testItem.hasDiscount, isTrue);
      expect(testItem.discountPercent, equals(20)); // (2000-1600)/2000 = 20%
    });

    test('no discount when mrp is null or lower/equal to price', () {
      final noDiscountItem = WishlistItemModel(
        productId: 'prod_pen',
        productName: 'Blue Pen Pack',
        price: 50.0,
        addedAt: fixedTime,
      );
      expect(noDiscountItem.hasDiscount, isFalse);
      expect(noDiscountItem.discountPercent, equals(0));

      final invalidMrpItem = noDiscountItem.copyWith(mrp: 50.0);
      expect(invalidMrpItem.hasDiscount, isFalse);
      expect(invalidMrpItem.discountPercent, equals(0));
    });

    test('creates WishlistItemModel from ProductModel', () {
      const discountedProduct = ProductModel(
        productId: 'prod_shoes',
        name: 'Action School Shoes',
        description: 'Black formal shoes',
        categoryId: 'cat_shoes',
        schoolName: 'Ryan International',
        basePrice: 1000.0,
        discountPrice: 750.0,
        images: ['https://cdn.bookvardi.com/shoes.png'],
        inStock: true,
      );

      final wishItem = WishlistItemModel.fromProduct(
        discountedProduct,
        addedAt: fixedTime,
      );

      expect(wishItem.productId, equals('prod_shoes'));
      expect(wishItem.productName, equals('Action School Shoes'));
      expect(wishItem.schoolName, equals('Ryan International'));
      expect(wishItem.imageUrl, equals('https://cdn.bookvardi.com/shoes.png'));
      expect(wishItem.price, equals(750.0));
      expect(wishItem.mrp, equals(1000.0));
      expect(wishItem.hasDiscount, isTrue);
      expect(wishItem.discountPercent, equals(25));
      expect(wishItem.inStock, isTrue);
      expect(wishItem.addedAt, equals(fixedTime));
    });

    test('copyWith updates specified fields only', () {
      final updated = testItem.copyWith(
        inStock: false,
        price: 1500.0,
      );

      expect(updated.inStock, isFalse);
      expect(updated.price, equals(1500.0));
      expect(updated.productName, equals(testItem.productName));
      expect(updated.discountPercent, equals(25)); // (2000-1500)/2000 = 25%
    });

    test('serialization toMap / fromMap and toJson / fromJson round-trips cleanly', () {
      final map = testItem.toMap();
      final fromMap = WishlistItemModel.fromMap(map);
      expect(fromMap, equals(testItem));

      final json = testItem.toJson();
      final fromJson = WishlistItemModel.fromJson(json);
      expect(fromJson, equals(testItem));
      expect(fromJson.hashCode, equals(testItem.hashCode));
    });

    test('value equality and toString', () {
      final clone = WishlistItemModel.fromMap(testItem.toMap());
      expect(clone, equals(testItem));
      expect(clone.hashCode, equals(testItem.hashCode));
      expect(testItem.toString(), contains('WishlistItemModel'));
      expect(testItem.toString(), contains('price: 1600.0'));
    });
  });
}
