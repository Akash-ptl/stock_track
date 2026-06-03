import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'stock_model.dart';

class StockRepository {
  
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

  String _getCacheKey(String businessId, String locationId) {
    return 'stock_items_key_${businessId}_$locationId';
  }

  bool _isDemo(String businessId, String locationId) {
    return businessId == 'biz_pizza_house' && locationId == 'loc_main_wh';
  }

  /// Fetch businesses for the user
  Future<List<Map<String, String>>> fetchBusinesses(String? authToken) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = authToken ?? prefs.getString('auth_token_key');

    final url = Uri.parse('https://stocktrack-mach.onrender.com/api/businesses');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        final List<Map<String, String>> result = body.map((biz) => {
          'id': biz['id'] as String,
          'name': biz['name'] as String,
        }).toList();

        await prefs.setString('cached_businesses_key', json.encode(result));
        return result;
      } else {
        throw Exception('Server returned status code ${response.statusCode} for businesses: ${response.body}');
      }
    } catch (e) {
      final cachedBizJson = prefs.getString('cached_businesses_key');
      if (cachedBizJson != null) {
        final List<dynamic> decoded = json.decode(cachedBizJson);
        return decoded.map((biz) => {
          'id': biz['id'] as String,
          'name': biz['name'] as String,
        }).toList();
      }
      throw Exception('Failed to load businesses from API: $e');
    }
  }

  /// Fetch locations for a business
  Future<List<Map<String, String>>> fetchLocations(String businessId, String? authToken) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = authToken ?? prefs.getString('auth_token_key');

    final url = Uri.parse('https://stocktrack-mach.onrender.com/api/businesses/$businessId/locations');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        final List<Map<String, String>> result = body.map((loc) => {
          'id': loc['id'] as String,
          'name': loc['name'] as String,
        }).toList();

        await prefs.setString('cached_locations_${businessId}_key', json.encode(result));
        return result;
      } else {
        throw Exception('Server returned status code ${response.statusCode} for locations: ${response.body}');
      }
    } catch (e) {
      final cachedLocsJson = prefs.getString('cached_locations_${businessId}_key');
      if (cachedLocsJson != null) {
        final List<dynamic> decoded = json.decode(cachedLocsJson);
        return decoded.map((loc) => {
          'id': loc['id'] as String,
          'name': loc['name'] as String,
        }).toList();
      }
      throw Exception('Failed to load locations from API: $e');
    }
  }

  /// Load stock items (API fallback to local SharedPreferences cache)
  Future<List<StockItem>> fetchStockItems({
    required String businessId,
    required String locationId,
    String? authToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = authToken ?? prefs.getString('auth_token_key');
    
    final String cacheKey = _getCacheKey(businessId, locationId);

    // 1. Check if we have cached local data
    final cachedData = prefs.getStringList(cacheKey);
    List<StockItem> itemsList = [];
    
    if (cachedData != null && cachedData.isNotEmpty) {
      itemsList = cachedData.map((e) => StockItem.fromJson(e)).toList();
    } else {
      if (_isDemo(businessId, locationId)) {
        // Initialize with mock items matching screenshot for demo/offline fallback business/location
        itemsList = List.from(_mockItems);
        await _saveToLocal(prefs, cacheKey, itemsList);
      } else {
        // Real user business/location has no local cache. Initialize empty.
        itemsList = [];
      }
    }

    // 2. Attempt to fetch from Backend API
    try {
      final url = Uri.parse(
        'https://stocktrack-mach.onrender.com/api/businesses/$businessId/locations/$locationId/stock-items',
      );
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        
        // Merge API items with local quantities (preserve offline unsynced values)
        final apiItems = body.map((jsonItem) {
          final mappedApiItem = StockItem.fromApiJson(jsonItem);
          
          // Check if we have local unsynced quantity for this item
          final localMatch = itemsList.firstWhere(
            (local) => local.id == mappedApiItem.id || local.sku == mappedApiItem.sku,
            orElse: () => mappedApiItem,
          );

          if (!localMatch.isSynced) {
            // Keep local quantity and unsynced status
            return localMatch.copyWith(
              name: mappedApiItem.name,
              sku: mappedApiItem.sku,
              unit: mappedApiItem.unit,
              packSizeMultiplier: mappedApiItem.packSizeMultiplier,
              parentUnit: mappedApiItem.parentUnit,
              imageUrl: mappedApiItem.imageUrl,
            );
          } else {
            // Take API item
            return mappedApiItem;
          }
        }).toList();

        // Always overwrite itemsList (even if empty, showing real server state)
        itemsList = apiItems;
        await _saveToLocal(prefs, cacheKey, itemsList);
      } else {
        throw Exception('Server returned status code ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Rethrow explicit server exceptions or client errors
      if (e.toString().contains('status code') || e is http.ClientException) {
        rethrow;
      }
      // If we are offline and have no cached data, rethrow to show offline error
      if (cachedData == null || cachedData.isEmpty) {
        rethrow;
      }
      // Otherwise fallback to cached data silently
    }

    return itemsList;
  }

  /// Save stock quantity locally
  Future<List<StockItem>> saveLocalQuantity({
    required String itemId,
    required double quantity,
    required String businessId,
    required String locationId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String cacheKey = _getCacheKey(businessId, locationId);
    final cachedData = prefs.getStringList(cacheKey);
    
    if (cachedData == null) return [];

    final items = cachedData.map((e) => StockItem.fromJson(e)).toList();
    
    final updatedItems = items.map((item) {
      if (item.id == itemId) {
        final cartons = quantity ~/ item.packSizeMultiplier;
        final pieces = quantity % item.packSizeMultiplier;
        return item.copyWith(
          quantity: quantity,
          cartons: cartons.toDouble(),
          pieces: pieces.toDouble(),
          isSynced: false, // Mark unsynced
        );
      }
      return item;
    }).toList();

    await _saveToLocal(prefs, cacheKey, updatedItems);
    return updatedItems;
  }

  /// Save detailed stock quantity from update screen locally
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
    final prefs = await SharedPreferences.getInstance();
    final String cacheKey = _getCacheKey(businessId, locationId);
    final cachedData = prefs.getStringList(cacheKey);
    
    if (cachedData == null) return [];

    final items = cachedData.map((e) => StockItem.fromJson(e)).toList();
    
    final updatedItems = items.map((item) {
      if (item.id == itemId) {
        final totalQty = (cartons * item.packSizeMultiplier) + pieces;
        return item.copyWith(
          quantity: totalQty,
          cartons: cartons,
          pieces: pieces,
          notes: notes,
          countType: countType,
          countDate: countDate,
          countedBy: countedBy,
          isSynced: false,
        );
      }
      return item;
    }).toList();

    await _saveToLocal(prefs, cacheKey, updatedItems);
    return updatedItems;
  }

  /// Push locally changed quantities to API
  Future<List<StockItem>> syncPendingRecords({
    required String businessId,
    required String locationId,
    String? authToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = authToken ?? prefs.getString('auth_token_key');
    
    final String cacheKey = _getCacheKey(businessId, locationId);
    final cachedData = prefs.getStringList(cacheKey);
    if (cachedData == null) return [];

    final items = cachedData.map((e) => StockItem.fromJson(e)).toList();
    final unsyncedItems = items.where((element) => !element.isSynced).toList();

    if (unsyncedItems.isEmpty) {
      return items; // Nothing to sync
    }

    final String countDate = DateTime.now().toIso8601String().split('T')[0];
    
    // Find the countedBy name from the unsynced items or use a default
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

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final postUrl = Uri.parse(
      'https://stocktrack-mach.onrender.com/api/businesses/$businessId/stock-counts',
    );

    // 1. POST to create count session
    final postResponse = await http.post(
      postUrl,
      headers: headers,
      body: json.encode(payload),
    ).timeout(const Duration(seconds: 10));

    if (postResponse.statusCode == 200 || postResponse.statusCode == 201) {
      final sessionData = json.decode(postResponse.body);
      final sessionId = sessionData['id'] as String;

      // 2. PUT to finalize and commit the count session
      final putUrl = Uri.parse(
        'https://stocktrack-mach.onrender.com/api/businesses/$businessId/stock-counts/$sessionId?status=completed',
      );

      final putResponse = await http.put(
        putUrl,
        headers: headers,
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 10));

      if (putResponse.statusCode == 200) {
        // Mark all unsynced items as synced
        final syncedItems = items.map((item) {
          if (!item.isSynced) {
            return item.copyWith(isSynced: true);
          }
          return item;
        }).toList();

        await _saveToLocal(prefs, cacheKey, syncedItems);
        return syncedItems;
      } else {
        throw Exception('Server failed to finalize count session: ${putResponse.body}');
      }
    } else {
      throw Exception('Server failed to create count session: ${postResponse.body}');
    }
  }

  Future<void> _saveToLocal(SharedPreferences prefs, String cacheKey, List<StockItem> items) async {
    final data = items.map((e) => e.toJson()).toList();
    await prefs.setStringList(cacheKey, data);
  }
}
