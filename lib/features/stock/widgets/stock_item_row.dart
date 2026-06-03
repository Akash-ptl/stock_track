import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_theme.dart';
import '../stock_model.dart';

/// Custom Row widget for each stock item to handle its text input state independently,
/// preventing cursor reset / focus loss on list view rebuilds.
class StockItemRow extends StatefulWidget {
  final StockItem item;

  const StockItemRow({
    super.key,
    required this.item,
  });

  @override
  State<StockItemRow> createState() => _StockItemRowState();
}

class _StockItemRowState extends State<StockItemRow> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final quantityStr = widget.item.quantity % 1 == 0
        ? widget.item.quantity.toInt().toString()
        : widget.item.quantity.toString();
    _controller = TextEditingController(text: quantityStr);
  }

  @override
  void didUpdateWidget(covariant StockItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update text if quantity changed from outside (e.g. server sync or reset)
    if (oldWidget.item.quantity != widget.item.quantity) {
      final quantityStr = widget.item.quantity % 1 == 0
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toString();
      if (_controller.text != quantityStr) {
        _controller.text = quantityStr;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Product Image Card (8px rounded corner, thin grey border)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: widget.item.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primaryNavy,
                              size: 18,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primaryNavy,
                          size: 18,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            
            // 2. Product Name & SKU
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${widget.item.sku}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (!widget.item.isSynced)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 10,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Unsaved offline changes',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // 3. Rounded Input Box for Quantity (Read-only)
            SizedBox(
              width: 52,
              height: 32,
              child: TextField(
                controller: _controller,
                readOnly: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // 4. Unit Label
            SizedBox(
              width: 32,
              child: Text(
                widget.item.unit,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
