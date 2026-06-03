import 'dart:convert';

class StockItem {
  final String id;
  final String name;
  final String sku;
  final String unit;
  final double quantity;
  final String imageUrl;
  final bool isSynced;
  
  // Detailed count fields
  final double cartons;
  final double pieces;
  final int packSizeMultiplier;
  final String parentUnit;
  final String notes;
  final String countType;
  final String countDate;
  final String countedBy;

  StockItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    required this.quantity,
    required this.imageUrl,
    this.isSynced = true,
    this.cartons = 0.0,
    this.pieces = 0.0,
    this.packSizeMultiplier = 1,
    this.parentUnit = 'carton',
    this.notes = '',
    this.countType = 'General Count',
    this.countDate = '',
    this.countedBy = '',
  });

  StockItem copyWith({
    String? id,
    String? name,
    String? sku,
    String? unit,
    double? quantity,
    String? imageUrl,
    bool? isSynced,
    double? cartons,
    double? pieces,
    int? packSizeMultiplier,
    String? parentUnit,
    String? notes,
    String? countType,
    String? countDate,
    String? countedBy,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      isSynced: isSynced ?? this.isSynced,
      cartons: cartons ?? this.cartons,
      pieces: pieces ?? this.pieces,
      packSizeMultiplier: packSizeMultiplier ?? this.packSizeMultiplier,
      parentUnit: parentUnit ?? this.parentUnit,
      notes: notes ?? this.notes,
      countType: countType ?? this.countType,
      countDate: countDate ?? this.countDate,
      countedBy: countedBy ?? this.countedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'unit': unit,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'isSynced': isSynced ? 1 : 0,
      'cartons': cartons,
      'pieces': pieces,
      'packSizeMultiplier': packSizeMultiplier,
      'parentUnit': parentUnit,
      'notes': notes,
      'countType': countType,
      'countDate': countDate,
      'countedBy': countedBy,
    };
  }

  factory StockItem.fromApiJson(Map<String, dynamic> jsonItem) {
    final String id = jsonItem['id'] ?? '';
    final String name = jsonItem['name'] ?? '';
    final String sku = jsonItem['sku'] ?? '';
    final String imageUrl = jsonItem['image_url'] ?? '';
    final String baseUnit = jsonItem['base_unit'] ?? 'pcs';
    final double currentStock = (jsonItem['current_stock'] as num?)?.toDouble() ?? 0.0;
    
    // Parse counting options to find pack size multiplier
    int multiplier = 1;
    String parentUnit = 'carton';
    
    final List<dynamic> options = jsonItem['counting_options'] ?? [];
    if (options.isNotEmpty) {
      // Find the first option where show_on_mobile is true and conversion_to_base_qty > 1
      dynamic mobileOption;
      for (final opt in options) {
        if ((opt['show_on_mobile'] == true) && 
            (((opt['conversion_to_base_qty'] as num?)?.toDouble() ?? 0.0) > 1.0)) {
          mobileOption = opt;
          break;
        }
      }
      
      if (mobileOption != null) {
        multiplier = (mobileOption['conversion_to_base_qty'] as num).toInt();
        parentUnit = mobileOption['level_name'] ?? 'carton';
      } else {
        // Fallback to first option if any conversion is > 1
        final firstOpt = options.first;
        final qty = (firstOpt['conversion_to_base_qty'] as num?)?.toDouble() ?? 1.0;
        if (qty > 1.0) {
          multiplier = qty.toInt();
          parentUnit = firstOpt['level_name'] ?? 'carton';
        }
      }
    }
    
    return StockItem(
      id: id,
      name: name,
      sku: sku,
      unit: baseUnit,
      quantity: currentStock,
      imageUrl: imageUrl,
      packSizeMultiplier: multiplier,
      parentUnit: parentUnit,
      isSynced: true,
      cartons: 0.0,
      pieces: 0.0,
      notes: '',
      countType: 'General Count',
      countDate: '',
      countedBy: '',
    );
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      unit: map['unit'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
      cartons: (map['cartons'] as num?)?.toDouble() ?? 0.0,
      pieces: (map['pieces'] as num?)?.toDouble() ?? 0.0,
      packSizeMultiplier: (map['packSizeMultiplier'] as num?)?.toInt() ?? 1,
      parentUnit: map['parentUnit'] ?? 'carton',
      notes: map['notes'] ?? '',
      countType: map['countType'] ?? 'General Count',
      countDate: map['countDate'] ?? '',
      countedBy: map['countedBy'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory StockItem.fromJson(String source) => StockItem.fromMap(json.decode(source));
}
