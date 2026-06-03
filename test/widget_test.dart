import 'package:flutter_test/flutter_test.dart';
import 'package:stock_track/features/stock/stock_model.dart';

void main() {
  test('StockItem serialization and deserialization test', () {
    final item = StockItem(
      id: 'item_test',
      name: 'Test Flour',
      sku: 'FLR-TEST',
      unit: 'kg',
      quantity: 5.0,
      imageUrl: 'https://example.com/image.png',
      isSynced: true,
      cartons: 1.0,
      pieces: 1.0,
      packSizeMultiplier: 4,
      parentUnit: 'case',
      notes: 'Test notes',
      countType: 'General Count',
      countDate: '2026-06-03',
      countedBy: 'Tester',
    );

    final map = item.toMap();
    final fromMapItem = StockItem.fromMap(map);

    expect(fromMapItem.id, 'item_test');
    expect(fromMapItem.name, 'Test Flour');
    expect(fromMapItem.sku, 'FLR-TEST');
    expect(fromMapItem.unit, 'kg');
    expect(fromMapItem.quantity, 5.0);
    expect(fromMapItem.imageUrl, 'https://example.com/image.png');
    expect(fromMapItem.isSynced, true);
    expect(fromMapItem.cartons, 1.0);
    expect(fromMapItem.pieces, 1.0);
    expect(fromMapItem.packSizeMultiplier, 4);
    expect(fromMapItem.parentUnit, 'case');
    expect(fromMapItem.notes, 'Test notes');
    expect(fromMapItem.countType, 'General Count');
    expect(fromMapItem.countDate, '2026-06-03');
    expect(fromMapItem.countedBy, 'Tester');
  });

  test('StockItem.fromApiJson mapping test', () {
    final apiJson = {
      'id': 'api_item_1',
      'name': 'API Sauce',
      'sku': 'SAU-API',
      'image_url': 'https://example.com/sauce.png',
      'base_unit': 'can',
      'current_stock': 12.0,
      'counting_options': [
        {
          'id': 'opt_1',
          'item_id': 'api_item_1',
          'business_id': 'biz_1',
          'level_name': 'Case',
          'display_name': 'Case of 6',
          'conversion_to_base_qty': 6.0,
          'base_unit': 'can',
          'sort_order': 1,
          'show_on_mobile': true,
        }
      ]
    };

    final item = StockItem.fromApiJson(apiJson);

    expect(item.id, 'api_item_1');
    expect(item.name, 'API Sauce');
    expect(item.sku, 'SAU-API');
    expect(item.unit, 'can');
    expect(item.quantity, 12.0);
    expect(item.imageUrl, 'https://example.com/sauce.png');
    expect(item.packSizeMultiplier, 6);
    expect(item.parentUnit, 'Case');
    expect(item.isSynced, true);
  });
}
