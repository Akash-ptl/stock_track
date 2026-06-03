import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';
import '../auth/auth_bloc/auth_bloc.dart';
import 'stock_bloc/stock_bloc.dart';
import 'stock_model.dart';

class StockCountUpdateArguments {
  final StockItem item;
  final String businessName;
  final String locationName;

  const StockCountUpdateArguments({
    required this.item,
    required this.businessName,
    required this.locationName,
  });
}

class StockCountUpdatePage extends StatefulWidget {
  const StockCountUpdatePage({super.key});

  @override
  State<StockCountUpdatePage> createState() => _StockCountUpdatePageState();
}

class _StockCountUpdatePageState extends State<StockCountUpdatePage> {
  late TextEditingController _cartonsController;
  late TextEditingController _piecesController;
  late TextEditingController _notesController;
  late TextEditingController _countedByController;

  bool _isInitialized = false;
  late StockCountUpdateArguments _args;
  DateTime _selectedDate = DateTime.now();
  String _countType = 'General Count';
  double _totalQuantity = 0.0;

  @override
  void initState() {
    super.initState();
    _cartonsController = TextEditingController();
    _piecesController = TextEditingController();
    _notesController = TextEditingController();
    _countedByController = TextEditingController();

    _cartonsController.addListener(_calculateTotal);
    _piecesController.addListener(_calculateTotal);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _args = ModalRoute.of(context)!.settings.arguments as StockCountUpdateArguments;
      final item = _args.item;

      // Unsynced local counts are prefilled to avoid data loss, while new counts start empty
      if (!item.isSynced) {
        _cartonsController.text = item.cartons > 0 ? (item.cartons % 1 == 0 ? item.cartons.toInt().toString() : item.cartons.toString()) : '';
        _piecesController.text = item.pieces > 0 ? (item.pieces % 1 == 0 ? item.pieces.toInt().toString() : item.pieces.toString()) : '';
      } else {
        _cartonsController.text = '';
        _piecesController.text = '';
      }

      _notesController.text = item.notes;

      // Default Counted By
      final authState = context.read<AuthBloc>().state;
      String defaultUser = 'Akash Kalathiya';
      if (item.countedBy.isNotEmpty) {
        defaultUser = item.countedBy;
      } else if (authState is Authenticated) {
        defaultUser = authState.user.displayName ?? 'Akash Kalathiya';
      }
      _countedByController.text = defaultUser;

      // Date initialization supporting both slash and dash separators
      if (item.countDate.isNotEmpty) {
        try {
          if (item.countDate.contains('/')) {
            final parts = item.countDate.split('/');
            if (parts.length == 3) {
              _selectedDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          } else if (item.countDate.contains('-')) {
            final parts = item.countDate.split('-');
            if (parts.length == 3) {
              _selectedDate = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
            }
          }
        } catch (_) {}
      }

      _countType = item.countType.isNotEmpty ? item.countType : 'General Count';
      _calculateTotal();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _cartonsController.dispose();
    _piecesController.dispose();
    _notesController.dispose();
    _countedByController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final cartons = double.tryParse(_cartonsController.text) ?? 0.0;
    final pieces = double.tryParse(_piecesController.text) ?? 0.0;
    setState(() {
      _totalQuantity = (cartons * _args.item.packSizeMultiplier) + pieces;
    });
  }

  String get _formattedDate {
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    return "$day/$month/${_selectedDate.year}";
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _cartonsController.clear();
      _piecesController.clear();
      _notesController.clear();
      _totalQuantity = 0.0;
    });
  }

  void _save(bool andSync) {
    final cartons = double.tryParse(_cartonsController.text) ?? 0.0;
    final pieces = double.tryParse(_piecesController.text) ?? 0.0;
    final notes = _notesController.text;
    final countedBy = _countedByController.text;

    // Dispatch save event
    context.read<StockBloc>().add(
      DetailedCountSaved(
        itemId: _args.item.id,
        cartons: cartons,
        pieces: pieces,
        notes: notes,
        countType: _countType,
        countDate: _formattedDate,
        countedBy: countedBy,
      ),
    );

    if (andSync) {
      // Trigger sync
      context.read<StockBloc>().add(const SyncRequested());
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = _args.item;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundSlate, // Off-white mockup background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryNavy,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Stock Count',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Subtitle description
                  Text(
                    'Count your stock items for accurate inventory tracking.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.neutralGray,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 1: Session Details Card
                  _buildSectionCard(
                    title: 'SESSION PARAMETERS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Business & Location (Read-only labels)
                        Row(
                          children: [
                            Expanded(
                              child: _buildReadOnlyField(
                                label: 'BUSINESS',
                                value: _args.businessName,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildReadOnlyField(
                                label: 'LOCATION',
                                value: _args.locationName,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Count Type Dropdown
                        Text(
                          'COUNT TYPE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutralGray,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _countType,
                              isDense: true,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: const [
                                DropdownMenuItem(value: 'General Count', child: Text('General Count')),
                                DropdownMenuItem(value: 'Cycle Count', child: Text('Cycle Count')),
                                DropdownMenuItem(value: 'Ad-hoc Count', child: Text('Ad-hoc Count')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _countType = val;
                                  });
                                }
                              },
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Count Date picker
                        Text(
                          'COUNT DATE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutralGray,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _presentDatePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderGray),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formattedDate,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: AppColors.neutralGray,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Counted By Text Field
                        Text(
                          'COUNTED BY',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutralGray,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _countedByController,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryNavy,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.borderGray),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 2: Product Multiplier Info Card
                  _buildSectionCard(
                    title: 'ITEM DETAILS',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Image
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.fastfood_outlined,
                                color: AppColors.neutralGray,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Item Info & Multiplier
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SKU: ${item.sku}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.neutralGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Unit multiplier info container
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundSlate,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.lightGray),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 13,
                                      color: AppColors.primaryGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Unit Info: 1 ${item.parentUnit} = ${item.packSizeMultiplier} ${item.unit}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.neutralGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 3: Count Quantity Inputs
                  _buildSectionCard(
                    title: 'COUNTED QUANTITY',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            // Show Carton field only if multiplier > 1
                            if (item.packSizeMultiplier > 1) ...[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.parentUnit.toUpperCase()}S',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.neutralGray,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 38,
                                      child: TextField(
                                        controller: _cartonsController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryNavy,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '0',
                                          hintStyle: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.zero,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: AppColors.borderGray),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            
                            // Pieces field
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.unit.toUpperCase()}S / BASE',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.neutralGray,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: _piecesController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryNavy,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: EdgeInsets.zero,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.borderGray),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Total Calculated Box (Base Unit)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSlate,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL (BASE UNIT)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutralGray,
                                ),
                              ),
                              Text(
                                '${_totalQuantity.toStringAsFixed(2)} ${item.unit}',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 4: Notes
                  _buildSectionCard(
                    title: 'NOTES',
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.primaryNavy),
                      decoration: InputDecoration(
                        hintText: 'Add notes...',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.borderGray),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Clear All
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearAll,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        foregroundColor: const Color(0xFF475569),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'CLEAR ALL',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Save Draft
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _save(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryGreen),
                        foregroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'SAVE DRAFT',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Submit Count
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _save(true),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'SUBMIT COUNT',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralGray,
              letterSpacing: 0.5,
            ),
          ),
          const Divider(height: 16, color: AppColors.lightGray),
          child,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundSlate,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
