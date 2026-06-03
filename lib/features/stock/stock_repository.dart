import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/api_constants.dart';
import '../../core/database/app_database.dart';
import 'stock_model.dart';

class StockRepository {
  final FlutterSecureStorage _secureStorage;

  StockRepository({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // High-fidelity mock items representing the screenshot products
  final List<StockItem> _mockItems = [
    StockItem(
      id: 'item_1',
      name: '00 Pizza Flour 25kg',
      sku: 'FLR-00-25',
      unit: 'pcs',
      quantity: 12.0,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=100&q=80',
      isSynced: true,
      packSizeMultiplier: 1,
      parentUnit: 'pcs',
    ),
    StockItem(
      id: 'item_2',
      name: 'Tomato Sauce 4.1kg',
      sku: 'SAU-001',
      unit: 'can',
      quantity: 18.0,
      imageUrl: 'https://images.unsplash.com/photo-1607305387299-a3d9611cd46f?w=100&q=80',
      isSynced: true,
      packSizeMultiplier: 6,
      parentUnit: 'case',
    ),
    StockItem(
      id: 'item_3',
      name: 'Mozzarella Cheese 2.5kg',
      sku: 'CHS-MOZ-2.5',
      unit: 'kg',
      quantity: 9.5,
      imageUrl: 'https://images.unsplash.com/photo-1552763487-de2f8cc081a5?w=100&q=80',
      isSynced: true,
      packSizeMultiplier: 4,
      parentUnit: 'case',
    ),
    StockItem(
      id: 'item_4',
      name: 'Pepperoni Slices 1kg',
      sku: 'PEP-001',
      unit: 'pcs',
      quantity: 6.0,
      imageUrl: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=100&q=80',
      isSynced: true,
      packSizeMultiplier: 10,
      parentUnit: 'pack',
    ),
    StockItem(
      id: 'item_5',
      name: 'Green Capsicum',
      sku: 'VEG-GRN-CAP',
      unit: 'kg',
      quantity: 15.0,
      imageUrl: 'https://images.unsplash.com/photo-1563565312879-8a95d8d101e1?w=100&q=80',
      isSynced: true,
      packSizeMultiplier: 1,
      parentUnit: 'crate',
    ),
    StockItem(
      id: 'item_6',
      name: 'Red Onion',
      sku: 'VEG-RED-ONI',
      unit: 'kg',
      quantity: 8.0,
      imageUrl: 'https://images.unsplash.com/photo-1618519764620-7403abdbfee9?w=100&q=80',
      isSynced: true,
      packSizeMultiplier: 1,
      parentUnit: 'crate',
    ),
    StockItem(
      id: 'item_7',
      name: 'Button Mushrooms 2kg',
      sku: 'VEG-MUS-2',
      unit: 'kg',
      quantity: 7.0,
      imageUrl: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=100&q=80',
      isSynced: true,
      packSizeMultiplier: 1,
      parentUnit: 'crate',
    ),
  ];

  String _getCacheKey(String userId, String businessId, String locationId) {
    return 'stock_items_key_${userId}_${businessId}_$locationId';
  }

  bool _isDemo(String businessId, String locationId) {
    return businessId == 'biz_pizza_house' && locationId == 'loc_main_wh';
  }

  /// Migrates SharedPreferences cache entries to SQLite DB
  Future<void> migrateLegacyCache(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final db = await AppDatabase.database;

    // 1. Migrate businesses
    final cachedBizJson = prefs.getString('cached_businesses_key');
    if (cachedBizJson != null) {
      try {
        final List<dynamic> decoded = json.decode(cachedBizJson);
        final batch = db.batch();
        for (var biz in decoded) {
          batch.insert('businesses', {
            'user_uid': userId,
            'id': biz['id'] as String,
            'name': biz['name'] as String,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
        await prefs.remove('cached_businesses_key');
      } catch (e) {
        debugPrint('[StockRepository] migrate businesses error: $e');
      }
    }

    // 2. Migrate stock items
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('stock_items_key_')) {
        final parts = key.split('_');
        final cachedData = prefs.getStringList(key);
        if (cachedData != null && cachedData.isNotEmpty) {
          try {
            String businessId = '';
            String locationId = '';
            if (parts.length == 5) {
              businessId = parts[3];
              locationId = parts[4];
            } else if (parts.length == 6) {
              businessId = parts[4];
              locationId = parts[5];
            }
            if (businessId.isNotEmpty && locationId.isNotEmpty) {
              final batch = db.batch();
              for (var jsonStr in cachedData) {
                final item = StockItem.fromJson(jsonStr);
                batch.insert('stock_items', {
                  ...item.toMap(),
                  'user_uid': userId,
                  'business_id': businessId,
                  'location_id': locationId,
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              }
              await batch.commit(noResult: true);
            }
          } catch (e) {
            debugPrint('[StockRepository] migrate stock items error: $e');
          }
        }
        await prefs.remove(key);
      }
    }
  }

  /// Fetch businesses for the user
  Future<List<Map<String, String>>> fetchBusinesses(String? authToken) async {
    final String? token = authToken ?? await _secureStorage.read(key: 'auth_token_key');
    final String? userId = await _secureStorage.read(key: 'user_uid');
    final String userUid = userId ?? 'anonymous';

    // Migrate old caches if present
    if (userId != null) {
      await migrateLegacyCache(userId);
    }

    final db = await AppDatabase.database;
    final url = Uri.parse(ApiConstants.businesses);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    debugPrint('[StockRepository] fetchBusinesses: Requesting URL: $url');

    try {
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        final List<Map<String, String>> result = body.map((biz) => {
          'id': biz['id'] as String,
          'name': biz['name'] as String,
        }).toList();

        final batch = db.batch();
        batch.delete('businesses', where: 'user_uid = ?', whereArgs: [userUid]);
        for (var biz in result) {
          batch.insert('businesses', {
            'user_uid': userUid,
            'id': biz['id'],
            'name': biz['name'],
          });
        }
        await batch.commit(noResult: true);
        return result;
      } else {
        throw Exception('Server returned status code ${response.statusCode} for businesses');
      }
    } catch (e) {
      debugPrint('[StockRepository] fetchBusinesses: Error encountered: $e');
      final List<Map<String, dynamic>> maps = await db.query(
        'businesses',
        where: 'user_uid = ?',
        whereArgs: [userUid],
      );
      if (maps.isNotEmpty) {
        debugPrint('[StockRepository] fetchBusinesses: Fallback to SQLite cache');
        return maps.map((biz) => {
          'id': biz['id'] as String,
          'name': biz['name'] as String,
        }).toList();
      }
      throw Exception('Failed to load businesses from API: $e');
    }
  }

  /// Fetch locations for a business
  Future<List<Map<String, String>>> fetchLocations(String businessId, String? authToken) async {
    final String? token = authToken ?? await _secureStorage.read(key: 'auth_token_key');
    final String? userId = await _secureStorage.read(key: 'user_uid');
    final String userUid = userId ?? 'anonymous';

    final db = await AppDatabase.database;
    final url = Uri.parse(ApiConstants.locations(businessId));
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    debugPrint('[StockRepository] fetchLocations: Requesting URL: $url');

    try {
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        final List<Map<String, String>> result = body.map((loc) => {
          'id': loc['id'] as String,
          'name': loc['name'] as String,
        }).toList();

        final batch = db.batch();
        batch.delete('locations', where: 'user_uid = ? AND business_id = ?', whereArgs: [userUid, businessId]);
        for (var loc in result) {
          batch.insert('locations', {
            'user_uid': userUid,
            'business_id': businessId,
            'id': loc['id'],
            'name': loc['name'],
          });
        }
        await batch.commit(noResult: true);
        return result;
      } else {
        throw Exception('Server returned status code ${response.statusCode} for locations');
      }
    } catch (e) {
      debugPrint('[StockRepository] fetchLocations: Error encountered: $e');
      final List<Map<String, dynamic>> maps = await db.query(
        'locations',
        where: 'user_uid = ? AND business_id = ?',
        whereArgs: [userUid, businessId],
      );
      if (maps.isNotEmpty) {
        debugPrint('[StockRepository] fetchLocations: Fallback to SQLite cache');
        return maps.map((loc) => {
          'id': loc['id'] as String,
          'name': loc['name'] as String,
        }).toList();
      }
      throw Exception('Failed to load locations from API: $e');
    }
  }

  /// Load stock items (API fallback to SQLite local database)
  Future<List<StockItem>> fetchStockItems({
    required String businessId,
    required String locationId,
    String? authToken,
  }) async {
    final String? token = authToken ?? await _secureStorage.read(key: 'auth_token_key');
    final String? userId = await _secureStorage.read(key: 'user_uid');
    final String userUid = userId ?? 'anonymous';
    
    // Migrate old caches if present
    if (userId != null) {
      await migrateLegacyCache(userId);
    }

    final db = await AppDatabase.database;
    
    // Load local SQLite items
    final List<Map<String, dynamic>> localMaps = await db.query(
      'stock_items',
      where: 'user_uid = ? AND business_id = ? AND location_id = ?',
      whereArgs: [userUid, businessId, locationId],
    );

    List<StockItem> itemsList = localMaps.map((e) => StockItem.fromMap(e)).toList();

    if (itemsList.isEmpty && _isDemo(businessId, locationId)) {
      // Demo fallback initialization
      final batch = db.batch();
      for (var item in _mockItems) {
        batch.insert('stock_items', {
          ...item.toMap(),
          'user_uid': userUid,
          'business_id': businessId,
          'location_id': locationId,
        });
      }
      await batch.commit(noResult: true);
      itemsList = List.from(_mockItems);
    }

    if (_isDemo(businessId, locationId)) {
      debugPrint('[StockRepository] fetchStockItems: Demo mode detected. Returning items immediately.');
      return itemsList;
    }

    final url = Uri.parse(ApiConstants.stockItems(businessId, locationId));
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    debugPrint('[StockRepository] fetchStockItems: Requesting URL: $url');

    try {
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        final apiItems = body.map((jsonItem) => StockItem.fromApiJson(jsonItem)).toList();

        final batch = db.batch();
        final mergedItems = <StockItem>[];

        for (var apiItem in apiItems) {
          final localMatch = itemsList.firstWhere(
            (local) => local.id == apiItem.id || local.sku == apiItem.sku,
            orElse: () => apiItem,
          );

          final finalItem = !localMatch.isSynced
              ? localMatch.copyWith(
                  name: apiItem.name,
                  sku: apiItem.sku,
                  unit: apiItem.unit,
                  packSizeMultiplier: apiItem.packSizeMultiplier,
                  parentUnit: apiItem.parentUnit,
                  imageUrl: apiItem.imageUrl,
                )
              : apiItem;

          mergedItems.add(finalItem);

          batch.insert(
            'stock_items',
            {
              ...finalItem.toMap(),
              'user_uid': userUid,
              'business_id': businessId,
              'location_id': locationId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        return mergedItems;
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[StockRepository] fetchStockItems: Error encountered: $e');
      if (itemsList.isNotEmpty) {
        debugPrint('[StockRepository] fetchStockItems: Fallback to SQLite local cache');
        return itemsList;
      }
      rethrow;
    }
  }

  /// Save stock quantity locally in SQLite
  Future<List<StockItem>> saveLocalQuantity({
    required String itemId,
    required double quantity,
    required String businessId,
    required String locationId,
  }) async {
    final String? userId = await _secureStorage.read(key: 'user_uid');
    final String userUid = userId ?? 'anonymous';

    final db = await AppDatabase.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_items',
      where: 'user_uid = ? AND business_id = ? AND location_id = ?',
      whereArgs: [userUid, businessId, locationId],
    );

    final items = maps.map((e) => StockItem.fromMap(e)).toList();
    final updatedItems = <StockItem>[];
    final batch = db.batch();

    for (var item in items) {
      if (item.id == itemId) {
        final multiplier = item.packSizeMultiplier > 0 ? item.packSizeMultiplier : 1;
        final cartons = quantity ~/ multiplier;
        final pieces = quantity % multiplier;
        final updated = item.copyWith(
          quantity: quantity,
          cartons: cartons.toDouble(),
          pieces: pieces.toDouble(),
          isSynced: false,
        );
        updatedItems.add(updated);

        batch.update(
          'stock_items',
          {
            'quantity': quantity,
            'cartons': cartons.toDouble(),
            'pieces': pieces.toDouble(),
            'isSynced': 0,
          },
          where: 'user_uid = ? AND business_id = ? AND location_id = ? AND id = ?',
          whereArgs: [userUid, businessId, locationId, itemId],
        );
      } else {
        updatedItems.add(item);
      }
    }
    await batch.commit(noResult: true);
    return updatedItems;
  }

  /// Save detailed stock quantity in SQLite
  Future<List<StockItem>> saveDetailedLocalCount({
    required String itemId,
    required double cartons,
    required double pieces,
    required String notes,
    required String countType,
    required String countDate,
    required String countedBy,
    required String businessId,
    required String locationId,
  }) async {
    final String? userId = await _secureStorage.read(key: 'user_uid');
    final String userUid = userId ?? 'anonymous';

    final db = await AppDatabase.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_items',
      where: 'user_uid = ? AND business_id = ? AND location_id = ?',
      whereArgs: [userUid, businessId, locationId],
    );

    final items = maps.map((e) => StockItem.fromMap(e)).toList();
    final updatedItems = <StockItem>[];
    final batch = db.batch();

    for (var item in items) {
      if (item.id == itemId) {
        final totalQty = (cartons * item.packSizeMultiplier) + pieces;
        final updated = item.copyWith(
          quantity: totalQty,
          cartons: cartons,
          pieces: pieces,
          notes: notes,
          countType: countType,
          countDate: countDate,
          countedBy: countedBy,
          isSynced: false,
        );
        updatedItems.add(updated);

        batch.update(
          'stock_items',
          {
            'quantity': totalQty,
            'cartons': cartons,
            'pieces': pieces,
            'notes': notes,
            'countType': countType,
            'countDate': countDate,
            'countedBy': countedBy,
            'isSynced': 0,
          },
          where: 'user_uid = ? AND business_id = ? AND location_id = ? AND id = ?',
          whereArgs: [userUid, businessId, locationId, itemId],
        );
      } else {
        updatedItems.add(item);
      }
    }
    await batch.commit(noResult: true);
    return updatedItems;
  }

  /// Push locally changed quantities to API (Idempotent call)
  Future<List<StockItem>> syncPendingRecords({
    required String businessId,
    required String locationId,
    String? authToken,
  }) async {
    final String? token = authToken ?? await _secureStorage.read(key: 'auth_token_key');
    final String? userId = await _secureStorage.read(key: 'user_uid');
    final String userUid = userId ?? 'anonymous';

    final db = await AppDatabase.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_items',
      where: 'user_uid = ? AND business_id = ? AND location_id = ?',
      whereArgs: [userUid, businessId, locationId],
    );

    final items = maps.map((e) => StockItem.fromMap(e)).toList();
    final unsyncedItems = items.where((element) => !element.isSynced).toList();

    if (_isDemo(businessId, locationId)) {
      debugPrint('[StockRepository] syncPendingRecords: Demo mode detected. Mocking sync.');
      final syncedItems = items.map((item) {
        if (!item.isSynced) {
          return item.copyWith(isSynced: true);
        }
        return item;
      }).toList();

      final batch = db.batch();
      batch.update(
        'stock_items',
        {'isSynced': 1},
        where: 'user_uid = ? AND business_id = ? AND location_id = ? AND isSynced = 0',
        whereArgs: [userUid, businessId, locationId],
      );
      await batch.commit(noResult: true);
      return syncedItems;
    }

    if (unsyncedItems.isEmpty) {
      debugPrint('[StockRepository] syncPendingRecords: No unsynced records found.');
      return items;
    }

    // Align Date parsing: DD/MM/YYYY to YYYY-MM-DD
    final itemWithDate = unsyncedItems.firstWhere(
      (e) => e.countDate.isNotEmpty,
      orElse: () => StockItem(id: '', name: '', sku: '', unit: '', quantity: 0, imageUrl: ''),
    );
    String countDate = itemWithDate.countDate;
    if (countDate.contains('/')) {
      final parts = countDate.split('/');
      if (parts.length == 3) {
        countDate = "${parts[2]}-${parts[1]}-${parts[0]}";
      }
    }
    if (countDate.isEmpty) {
      countDate = DateTime.now().toIso8601String().split('T')[0];
    }
    
    final countedByName = unsyncedItems
        .firstWhere((e) => e.countedBy.isNotEmpty, orElse: () => StockItem(id: '', name: '', sku: '', unit: '', quantity: 0, imageUrl: ''))
        .countedBy;
    final displayName = countedByName.isNotEmpty ? countedByName : 'Mobile App User';

    // Construct body items matching StockCountItemCreate
    final List<Map<String, dynamic>> itemsPayload = unsyncedItems.map((item) {
      return {
        'item_id': item.id,
        'counted_cartons': item.packSizeMultiplier > 1 ? item.cartons : null,
        'counted_pieces': item.packSizeMultiplier > 1 ? item.pieces : item.quantity,
        'notes': item.notes.isNotEmpty ? item.notes : null,
      };
    }).toList();

    final payload = {
      'location_id': locationId,
      'count_type': 'General Count',
      'count_date': countDate,
      'counted_by_name': displayName,
      'notes': 'Sync from StockTrack Mobile App',
      'items': itemsPayload,
    };

    // Generate unique Idempotency-Key
    final String idempotencyKey = '${DateTime.now().millisecondsSinceEpoch}_$userUid';

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Idempotency-Key': idempotencyKey,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final postUrl = Uri.parse(
      ApiConstants.stockCounts(businessId),
    );

    debugPrint('[StockRepository] syncPendingRecords: POST URL: $postUrl (Key: $idempotencyKey)');

    // 1. POST to create count session
    final postResponse = await http.post(
      postUrl,
      headers: headers,
      body: json.encode(payload),
    ).timeout(const Duration(seconds: 60));

    if (postResponse.statusCode == 200 || postResponse.statusCode == 201) {
      final sessionData = json.decode(postResponse.body);
      final sessionId = sessionData['id'] as String;

      // 2. PUT to finalize and commit the count session
      final putUrl = Uri.parse(
        ApiConstants.finalizeCount(businessId, sessionId),
      );

      debugPrint('[StockRepository] syncPendingRecords: PUT URL: $putUrl');

      final putResponse = await http.put(
        putUrl,
        headers: headers,
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 60));

      if (putResponse.statusCode == 200) {
        final syncedItems = items.map((item) {
          if (!item.isSynced) {
            return item.copyWith(isSynced: true);
          }
          return item;
        }).toList();

        final batch = db.batch();
        batch.update(
          'stock_items',
          {'isSynced': 1},
          where: 'user_uid = ? AND business_id = ? AND location_id = ? AND isSynced = 0',
          whereArgs: [userUid, businessId, locationId],
        );
        await batch.commit(noResult: true);
        return syncedItems;
      } else {
        throw Exception('Server failed to finalize count session: ${putResponse.body}');
      }
    } else {
      throw Exception('Server failed to create count session: ${postResponse.body}');
    }
  }
}
