import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/catalog/domain/category_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/school_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';

void main() {
  group('CategoryModel Domain Tests', () {
    test('serializes to and from JSON cleanly', () {
      const category = CategoryModel(
        categoryId: 'cat_uniforms',
        name: 'School Uniforms',
        iconUrl: 'https://assets.bookvardi.com/icons/uniforms.png',
        displayOrder: 1,
      );

      final json = category.toJson();
      expect(json['categoryId'], equals('cat_uniforms'));
      expect(json['name'], equals('School Uniforms'));
      expect(json['iconUrl'], equals('https://assets.bookvardi.com/icons/uniforms.png'));
      expect(json['displayOrder'], equals(1));

      final fromJson = CategoryModel.fromJson(json);
      expect(fromJson, equals(category));
      expect(fromJson.hashCode, equals(category.hashCode));
    });

    test('copyWith creates new immutable copy with overridden properties', () {
      const original = CategoryModel(
        categoryId: 'cat_1',
        name: 'Books',
        iconUrl: 'icon1.png',
      );

      final updated = original.copyWith(name: 'Textbooks & Notebooks', displayOrder: 3);
      expect(updated.categoryId, equals('cat_1'));
      expect(updated.name, equals('Textbooks & Notebooks'));
      expect(updated.displayOrder, equals(3));
      expect(updated.iconUrl, equals('icon1.png'));
      expect(updated, isNot(equals(original)));
    });
  });

  group('VariantModel Domain Tests', () {
    test('serializes to and from JSON cleanly and detects stock', () {
      const variant = VariantModel(
        variantId: 'var_size_32',
        sku: 'UNI-SHIRT-32',
        label: 'Size 32 (Age 8-9)',
        price: 499.0,
        stock: 15,
      );

      expect(variant.inStock, isTrue);

      final json = variant.toJson();
      expect(json['variantId'], equals('var_size_32'));
      expect(json['sku'], equals('UNI-SHIRT-32'));
      expect(json['label'], equals('Size 32 (Age 8-9)'));
      expect(json['price'], equals(499.0));
      expect(json['stock'], equals(15));

      final fromJson = VariantModel.fromJson(json);
      expect(fromJson, equals(variant));
    });

    test('inStock returns false when stock is 0 or negative', () {
      const outOfStockVariant = VariantModel(
        variantId: 'var_oos',
        sku: 'UNI-OOS',
        label: 'Size 42',
        price: 650.0,
        stock: 0,
      );
      expect(outOfStockVariant.inStock, isFalse);
    });

    test('copyWith creates immutable clone with updated price', () {
      const v1 = VariantModel(
        variantId: 'v1',
        sku: 'SKU1',
        label: 'Medium',
        price: 300.0,
        stock: 5,
      );
      final v2 = v1.copyWith(price: 350.0, stock: 10);
      expect(v2.price, equals(350.0));
      expect(v2.stock, equals(10));
      expect(v2.variantId, equals('v1'));
      expect(v2, isNot(equals(v1)));
    });
  });

  group('SchoolModel Domain Tests', () {
    test('serializes to and from JSON cleanly with grade lists', () {
      const school = SchoolModel(
        schoolId: 'sch_dps_rkp',
        name: 'Delhi Public School, R.K. Puram',
        city: 'New Delhi',
        logoUrl: 'https://assets.bookvardi.com/schools/dps.png',
        grades: ['Nursery', 'KG', 'Class 1', 'Class 2', 'Class 3'],
      );

      final json = school.toJson();
      expect(json['schoolId'], equals('sch_dps_rkp'));
      expect(json['name'], equals('Delhi Public School, R.K. Puram'));
      expect(json['city'], equals('New Delhi'));
      expect(json['grades'], hasLength(5));

      final fromJson = SchoolModel.fromJson(json);
      expect(fromJson, equals(school));
      expect(fromJson.grades, contains('Class 1'));
    });

    test('copyWith updates school metadata and preserves grades', () {
      const school1 = SchoolModel(
        schoolId: 'sch_1',
        name: 'St. Xavier High School',
        city: 'Mumbai',
        logoUrl: 'logo.png',
        grades: ['Class 1', 'Class 2'],
      );

      final school2 = school1.copyWith(city: 'Navi Mumbai');
      expect(school2.city, equals('Navi Mumbai'));
      expect(school2.name, equals('St. Xavier High School'));
      expect(school2.grades, equals(['Class 1', 'Class 2']));
      expect(school2, isNot(equals(school1)));
    });
  });

  group('ProductModel Domain Tests', () {
    test('computes discounts and effective pricing accurately', () {
      const discountedProduct = ProductModel(
        productId: 'prod_bundle_1',
        title: 'Complete Grade 5 Textbook & Notebook Bundle',
        description: 'NCERT aligned standard textbook bundle including workbooks.',
        categoryId: 'cat_textbooks',
        schoolId: 'sch_dps_rkp',
        basePrice: 2000.0,
        discountPrice: 1600.0,
        images: ['https://assets.bookvardi.com/bundle5_1.jpg', 'https://assets.bookvardi.com/bundle5_2.jpg'],
        rating: 4.8,
        reviewCount: 42,
        inStock: true,
      );

      expect(discountedProduct.hasDiscount, isTrue);
      expect(discountedProduct.effectivePrice, equals(1600.0));
      expect(discountedProduct.discountPercentage, equals(20)); // (2000-1600)/2000 = 20%
      expect(discountedProduct.primaryImage, equals('https://assets.bookvardi.com/bundle5_1.jpg'));
    });

    test('handles non-discounted items with zero discount percentage', () {
      const regularProduct = ProductModel(
        productId: 'prod_tie',
        title: 'School House Tie (Blue)',
        description: 'Standard woven satin school tie',
        categoryId: 'cat_uniforms',
        basePrice: 250.0,
        discountPrice: null,
      );

      expect(regularProduct.hasDiscount, isFalse);
      expect(regularProduct.effectivePrice, equals(250.0));
      expect(regularProduct.discountPercentage, equals(0));
      expect(regularProduct.primaryImage, isEmpty);
    });

    test('serializes and deserializes cleanly with nested variants', () {
      const product = ProductModel(
        productId: 'prod_shoes',
        title: 'Action School White Canvas Shoes',
        description: 'Comfortable PT shoes for boys and girls',
        categoryId: 'cat_footwear',
        basePrice: 699.0,
        discountPrice: 599.0,
        images: ['shoes_front.png'],
        variants: [
          VariantModel(
            variantId: 'v_size_4',
            sku: 'ACT-WHT-4',
            label: 'Size 4',
            price: 599.0,
            stock: 12,
          ),
          VariantModel(
            variantId: 'v_size_5',
            sku: 'ACT-WHT-5',
            label: 'Size 5',
            price: 599.0,
            stock: 0,
          ),
        ],
        rating: 4.5,
        reviewCount: 18,
        inStock: true,
      );

      final json = product.toJson();
      expect(json['productId'], equals('prod_shoes'));
      expect((json['variants'] as List), hasLength(2));

      final fromJson = ProductModel.fromJson(json);
      expect(fromJson, equals(product));
      expect(fromJson.variants.first.label, equals('Size 4'));
      expect(fromJson.variants.last.inStock, isFalse);
    });

    test('copyWith produces updated immutable entity', () {
      const product = ProductModel(
        productId: 'p1',
        title: 'Original Title',
        description: 'Desc',
        categoryId: 'c1',
        basePrice: 100.0,
      );

      final updated = product.copyWith(title: 'New Title', basePrice: 120.0);
      expect(updated.title, equals('New Title'));
      expect(updated.basePrice, equals(120.0));
      expect(updated.productId, equals('p1'));
      expect(updated, isNot(equals(product)));
    });

    test('serializes and deserializes full PRD Section 5 schema fields', () {
      const fullProduct = ProductModel(
        productId: 'prod_dps_blazer',
        name: 'DPS Winter Woolen Blazer',
        description: 'Navy blue tailored school blazer with embroidered school crest.',
        categoryId: 'cat_uniforms',
        schoolId: 'sch_dps_rkp',
        schoolName: 'Delhi Public School, R.K. Puram',
        targetGrade: 'Class 9-12',
        basePrice: 2499.0,
        discountPrice: 2199.0,
        images: ['https://assets.bookvardi.com/blazer_front.jpg'],
        variants: [
          VariantModel(
            variantId: 'v_blazer_34',
            sku: 'DPS-BLZ-34',
            label: 'Size 34',
            price: 2199.0,
            stock: 25,
          ),
          VariantModel(
            variantId: 'v_blazer_36',
            sku: 'DPS-BLZ-36',
            label: 'Size 36',
            price: 2199.0,
            stock: 15,
          ),
        ],
        rating: 4.9,
        reviewCount: 30,
        inStock: true,
        isActive: true,
        isFeatured: true,
        totalStock: 40,
        specifications: {
          'material': 'Premium Terry Wool',
          'fit': 'Regular Fit',
          'care': 'Dry Clean Only',
          'board': 'CBSE',
        },
      );

      expect(fullProduct.hasVariants, isTrue);
      expect(fullProduct.isActive, isTrue);
      expect(fullProduct.isFeatured, isTrue);
      expect(fullProduct.totalStock, equals(40));
      expect(fullProduct.schoolName, equals('Delhi Public School, R.K. Puram'));
      expect(fullProduct.targetGrade, equals('Class 9-12'));
      expect(fullProduct.specifications['material'], equals('Premium Terry Wool'));

      final json = fullProduct.toJson();
      expect(json['name'], equals('DPS Winter Woolen Blazer'));
      expect(json['schoolName'], equals('Delhi Public School, R.K. Puram'));
      expect(json['targetGrade'], equals('Class 9-12'));
      expect(json['isActive'], isTrue);
      expect(json['isFeatured'], isTrue);
      expect(json['hasVariants'], isTrue);
      expect(json['totalStock'], equals(40));
      expect(json['specifications']['board'], equals('CBSE'));

      final fromJson = ProductModel.fromJson(json);
      expect(fromJson, equals(fullProduct));
    });
  });
}
