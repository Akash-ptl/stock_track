import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';
import '../auth/auth_bloc/auth_bloc.dart';
import 'stock_bloc/tenant_bloc.dart';
import 'stock_bloc/inventory_bloc.dart';
import 'stock_bloc/sync_bloc.dart';
import 'stock_count_update_page.dart';
import 'widgets/stock_item_row.dart';
import 'stock_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load tenants on launch
    context.read<TenantBloc>().add(const LoadTenantsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
        BlocListener<TenantBloc, TenantState>(
          listener: (context, state) {
            if (state.selectedBusinessId.isNotEmpty && state.selectedLocationId.isNotEmpty) {
              context.read<InventoryBloc>().add(
                    LoadInventoryRequested(
                      businessId: state.selectedBusinessId,
                      locationId: state.selectedLocationId,
                    ),
                  );
            }
          },
        ),
        BlocListener<SyncBloc, SyncState>(
          listener: (context, state) {
            if (state.syncError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.syncError!),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white, // Pure white background matching mockup
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  children: const [
                    TextSpan(text: 'Stock', style: TextStyle(color: AppColors.primaryNavy)),
                    TextSpan(text: 'Track', style: TextStyle(color: AppColors.primaryGreen)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            BlocBuilder<InventoryBloc, InventoryState>(
              builder: (context, inventoryState) {
                if (inventoryState is InventoryLoaded) {
                  final unsyncedCount = inventoryState.items.where((e) => !e.isSynced).length;
                  if (unsyncedCount > 0) {
                    return BlocBuilder<SyncBloc, SyncState>(
                      builder: (context, syncState) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: syncState.isSyncing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.sync_rounded,
                                      color: AppColors.primaryGreen,
                                    ),
                              tooltip: 'Sync pending changes',
                              onPressed: syncState.isSyncing
                                  ? null
                                  : () {
                                      final tenantState = context.read<TenantBloc>().state;
                                      context.read<SyncBloc>().add(
                                            SyncRequested(
                                              businessId: tenantState.selectedBusinessId,
                                              locationId: tenantState.selectedLocationId,
                                              onSyncCompleted: (syncedItems) {
                                                context.read<InventoryBloc>().add(
                                                      LocalItemsUpdated(items: syncedItems),
                                                    );
                                              },
                                            ),
                                          );
                                    },
                            ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$unsyncedCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.primaryNavy,
              ),
              tooltip: 'Sign Out',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to sign out of Stock Track?',
                      style: GoogleFonts.inter(
                        color: AppColors.neutralGray,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: AppColors.neutralGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          context.read<AuthBloc>().add(SignOutRequested());
                        },
                        child: Text(
                          'Sign Out',
                          style: GoogleFonts.inter(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: BlocBuilder<TenantBloc, TenantState>(
              builder: (context, tenantState) {
                if (tenantState.isLoading && tenantState.businesses.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    ),
                  );
                }

                if (tenantState.error != null && tenantState.businesses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Failed to load businesses: ${tenantState.error}'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<TenantBloc>().add(const LoadTenantsRequested()),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return BlocBuilder<InventoryBloc, InventoryState>(
                  builder: (context, inventoryState) {
                    if (inventoryState is InventoryLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                        ),
                      );
                    }

                    if (inventoryState is InventoryFailure) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Failed to load inventory: ${inventoryState.errorMessage}'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                context.read<InventoryBloc>().add(
                                      LoadInventoryRequested(
                                        businessId: tenantState.selectedBusinessId,
                                        locationId: tenantState.selectedLocationId,
                                      ),
                                    );
                              },
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }

                    final items = inventoryState is InventoryLoaded ? inventoryState.items : <StockItem>[];
                    final isLoadingNewData = inventoryState is InventoryLoaded ? inventoryState.isLoadingNewData : false;

                    return Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              final currentUnsynced = items.where((e) => !e.isSynced).length;
                              if (currentUnsynced > 0) {
                                context.read<SyncBloc>().add(
                                      SyncRequested(
                                        businessId: tenantState.selectedBusinessId,
                                        locationId: tenantState.selectedLocationId,
                                        onSyncCompleted: (syncedItems) {
                                          context.read<InventoryBloc>().add(
                                                LocalItemsUpdated(items: syncedItems),
                                              );
                                        },
                                      ),
                                    );
                              }
                              context.read<InventoryBloc>().add(
                                    LoadInventoryRequested(
                                      businessId: tenantState.selectedBusinessId,
                                      locationId: tenantState.selectedLocationId,
                                    ),
                                  );
                            },
                            color: AppColors.primaryGreen,
                            child: Stack(
                              children: [
                                Opacity(
                                  opacity: isLoadingNewData ? 0.45 : 1.0,
                                  child: AbsorbPointer(
                                    absorbing: isLoadingNewData,
                                    child: CustomScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      slivers: [
                                        SliverPadding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          sliver: SliverToBoxAdapter(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                const SizedBox(height: 12),
                                                _BusinessSelector(state: tenantState),
                                                const SizedBox(height: 10),
                                                _LocationSelector(state: tenantState),
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF4FBF7),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: AppColors.lightGreen.withValues(alpha: 0.6),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: const BoxDecoration(
                                                          color: AppColors.primaryGreen,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.assignment_outlined,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'Items to Update',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.bold,
                                                                color: AppColors.primaryNavy,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              'Enter the accurate quantity for each item.\nAll changes are saved automatically.',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 11,
                                                                color: AppColors.neutralGray,
                                                                height: 1.25,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'ITEM',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.neutralGray.withValues(alpha: 0.8),
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    Text(
                                                      'CURRENT QTY',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.neutralGray.withValues(alpha: 0.8),
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(height: 10, color: AppColors.borderGray),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (items.isEmpty)
                                          SliverPadding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
                                            sliver: SliverToBoxAdapter(
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.inventory_2_outlined,
                                                      color: AppColors.neutralGray,
                                                      size: 40,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'No stock items found',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.primaryNavy,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Configure stock items in the Web Admin dashboard.',
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: AppColors.neutralGray,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          SliverPadding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                            sliver: SliverList.separated(
                                              itemCount: items.length,
                                              separatorBuilder: (context, index) => const Divider(
                                                height: 1,
                                                color: AppColors.lightGray,
                                              ),
                                              itemBuilder: (context, index) {
                                                final item = items[index];
                                                return GestureDetector(
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () {
                                                    final currentBiz = tenantState.businesses.firstWhere(
                                                      (e) => e['id'] == tenantState.selectedBusinessId,
                                                      orElse: () => {'name': 'Pizza House'},
                                                    );
                                                    final currentLoc = tenantState.locations.firstWhere(
                                                      (e) => e['id'] == tenantState.selectedLocationId,
                                                      orElse: () => {'name': 'Main Warehouse'},
                                                    );

                                                    Navigator.pushNamed(
                                                      context,
                                                      '/update-count',
                                                      arguments: StockCountUpdateArguments(
                                                        item: item,
                                                        businessName: currentBiz['name'] ?? 'Pizza House',
                                                        locationName: currentLoc['name'] ?? 'Main Warehouse',
                                                      ),
                                                    );
                                                  },
                                                  child: StockItemRow(
                                                    key: ValueKey(item.id),
                                                    item: item,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: 24),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isLoadingNewData)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4FBF7),
                            border: Border(
                              top: BorderSide(
                                color: AppColors.lightGreen.withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryGreen,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'All changes are saved automatically. You can close the app when finished.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BusinessSelector extends StatelessWidget {
  final TenantState state;

  const _BusinessSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.neutralGray,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.selectedBusinessId,
                isDense: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryNavy,
                ),
                dropdownColor: Colors.white,
                isExpanded: true,
                items: state.businesses.isEmpty
                    ? [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryNavy,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.storefront_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'No businesses configured',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                        )
                      ]
                    : state.businesses.map((biz) {
                        return DropdownMenuItem<String>(
                          value: biz['id'],
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryNavy,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  (biz['name'] ?? 'B').isNotEmpty
                                      ? (biz['name'] ?? 'B')[0].toUpperCase()
                                      : 'B',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                biz['name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                onChanged: state.businesses.isEmpty || state.isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          context.read<TenantBloc>().add(BusinessChanged(businessId: value));
                        }
                      },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationSelector extends StatelessWidget {
  final TenantState state;

  const _LocationSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.neutralGray,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.selectedLocationId,
                isDense: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryNavy,
                ),
                dropdownColor: Colors.white,
                isExpanded: true,
                items: state.locations.isEmpty
                    ? [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.location_off_outlined,
                                  color: AppColors.error,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'No locations configured',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        )
                      ]
                    : state.locations.map((loc) {
                        return DropdownMenuItem<String>(
                          value: loc['id'],
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.primaryGreen,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                loc['name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                onChanged: state.locations.isEmpty || state.isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          context.read<TenantBloc>().add(LocationChanged(locationId: value));
                        }
                      },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
