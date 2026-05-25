import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/app_state_provider.dart';
import '../models/pharmacy_models.dart';
import '../utils/invoice_printer.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  final _searchController = TextEditingController();
  final _discountController = TextEditingController();
  final _cashReceivedController = TextEditingController();

  String _selectedCategory = 'Tous';
  String _paymentMethod = 'ESPECES'; // 'ESPECES', 'CREDIT', 'ORANGE MONEY'

  // Selection states
  bool _isCartVisible = true;

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _cashReceivedController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat.decimalPattern('fr').format(amount)} GNF';
  }

  // ignore: unused_element
  Widget _buildProductImage(Product prod, double height) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (prod.image.isNotEmpty &&
        !prod.image.startsWith('generic_pill') &&
        prod.image.length > 50) {
      try {
        final decodedBytes = base64Decode(
          prod.image.contains(',') ? prod.image.split(',').last : prod.image,
        );
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(decodedBytes, fit: BoxFit.cover),
        );
      } catch (e) {
        // Fallback to placeholder if error occurs
      }
    }

    // Select gradient colors and icons based on product category to make it look realistic
    List<Color> gradientColors;
    IconData categoryIcon;
    switch (prod.category) {
      case 'Antibiotiques':
        gradientColors = [Color(0xFF3B82F6), Color(0xFF1D4ED8)]; // Blue
        categoryIcon = Icons.biotech_rounded;
        break;
      case 'Anti-inflammatoires':
        gradientColors = [Color(0xFFEF4444), Color(0xFFB91C1C)]; // Red/Orange
        categoryIcon = Icons.healing_rounded;
        break;
      case 'Antispasmodiques':
        gradientColors = [Color(0xFFEC4899), Color(0xFFBE185D)]; // Pink
        categoryIcon = Icons.spa_rounded;
        break;
      case 'Pneumologie / Asthme':
        gradientColors = [Color(0xFF06B6D4), Color(0xFF0891B2)]; // Cyan
        categoryIcon = Icons.air_rounded;
        break;
      case 'Gastro-entérologie':
        gradientColors = [Color(0xFFF59E0B), Color(0xFFD97706)]; // Amber
        categoryIcon = Icons.vaccines_rounded;
        break;
      case 'Antihistaminiques':
        gradientColors = [Color(0xFF8B5CF6), Color(0xFF6D28D9)]; // Purple
        categoryIcon = Icons.layers_rounded;
        break;
      case 'Antalgiques':
      default:
        gradientColors = [
          Color(0xFF10B981),
          Color(0xFF047857),
        ]; // Emerald Green
        categoryIcon = Icons.medication_rounded;
        break;
    }

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Grid pattern effect
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: GridPaper(
                color: state.textPrimary,
                divisions: 1,
                subdivisions: 1,
                interval: 20,
              ),
            ),
          ),
          // Decorative glowing circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Pill Illustration or Medicine Icon
          Center(
            child: Hero(
              tag: 'prod-icon-${prod.id}',
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(categoryIcon, color: state.textPrimary, size: 28),
              ),
            ),
          ),
          // Brand/Tech Tag overlay
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                prod.id,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProductImage(Product prod, double size) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (prod.image.isNotEmpty &&
        !prod.image.startsWith('generic_pill') &&
        prod.image.length > 50) {
      try {
        final decodedBytes = base64Decode(
          prod.image.contains(',') ? prod.image.split(',').last : prod.image,
        );
        return Image.memory(
          decodedBytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } catch (e) {
        // Fallback
      }
    }

    List<Color> gradientColors;
    IconData categoryIcon;
    switch (prod.category) {
      case 'Antibiotiques':
        gradientColors = [Color(0xFF3B82F6), Color(0xFF1D4ED8)]; // Blue
        categoryIcon = Icons.biotech_rounded;
        break;
      case 'Anti-inflammatoires':
        gradientColors = [Color(0xFFEF4444), Color(0xFFB91C1C)]; // Red
        categoryIcon = Icons.healing_rounded;
        break;
      case 'Antispasmodiques':
        gradientColors = [Color(0xFFEC4899), Color(0xFFBE185D)]; // Pink
        categoryIcon = Icons.spa_rounded;
        break;
      case 'Pneumologie / Asthme':
        gradientColors = [Color(0xFF06B6D4), Color(0xFF0891B2)]; // Cyan
        categoryIcon = Icons.air_rounded;
        break;
      case 'Gastro-entérologie':
        gradientColors = [Color(0xFFF59E0B), Color(0xFFD97706)]; // Amber
        categoryIcon = Icons.vaccines_rounded;
        break;
      case 'Antihistaminiques':
        gradientColors = [Color(0xFF8B5CF6), Color(0xFF6D28D9)]; // Purple
        categoryIcon = Icons.layers_rounded;
        break;
      case 'Antalgiques':
      default:
        gradientColors = [
          Color(0xFF10B981),
          Color(0xFF047857),
        ]; // Emerald Green
        categoryIcon = Icons.medication_rounded;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(categoryIcon, color: Colors.white, size: size * 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final state = Provider.of<AppStateProvider>(context);
    final themeColor = Color(0xFF10B981);

    final filteredProducts = state.products.where((p) {
      final matchesQuery =
          p.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          p.barcode.contains(_searchController.text);
      final matchesCat =
          _selectedCategory == 'Tous' || p.category == _selectedCategory;
      final isInStock = p.totalQuantity > 0;
      return matchesQuery && matchesCat && isInStock;
    }).toList();

    // Active calculations
    // ignore: unused_local_variable
    double subtotal = state.cartTotal;
    double netTotal = state.cartNetTotal;
    double cashReceived = double.tryParse(_cashReceivedController.text) ?? 0.0;
    double changeReturned = cashReceived - netTotal;
    if (changeReturned < 0) changeReturned = 0.0;

    return Scaffold(
      backgroundColor: state.bgPrimary,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // LEFT SIDE: PRODUCTS GRID CATALOGUE
          // ==========================================
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fast POS bar
                  Row(
                    children: [
                      if (state.cart.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: themeColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: themeColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${state.cart.length} Sélectionné(s)',
                                style: GoogleFonts.inter(
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.inter(
                            color: state.textPrimary,
                            fontSize: 13.5,
                          ),
                          onChanged: (val) {
                            setState(() {}); // Trigger local rebuild for filter
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: state.bgSecondary,
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: state.textSecondaryLight,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: state.textSecondaryLight,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            hintText: 'Recherche produit (Nom, Code-Barres)...',
                            hintStyle: GoogleFonts.inter(
                              color: state.textSecondaryLight,
                              fontSize: 13,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          (() {
                            final dynamicCats = state.products
                                .map((p) => p.category)
                                .toSet()
                                .toList();
                            dynamicCats.sort(
                              (a, b) =>
                                  a.toLowerCase().compareTo(b.toLowerCase()),
                            );
                            return ['Tous', ...dynamicCats];
                          })().map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = cat;
                                    });
                                  }
                                },
                                selectedColor: themeColor,
                                backgroundColor: state.bgSecondary,
                                labelStyle: GoogleFonts.inter(
                                  color: isSelected
                                      ? Colors.white
                                      : state.textSecondaryLight,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  color: state.textSecondaryLight,
                                  size: 48,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Aucun produit trouvé',
                                  style: GoogleFonts.outfit(
                                    color: state.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = (constraints.maxWidth / 260)
                                  .floor();
                              if (crossAxisCount < 1) crossAxisCount = 1;
                              return GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      mainAxisExtent: 110,
                                    ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final prod = filteredProducts[index];
                                  final isOutOfStock = prod.totalQuantity <= 0;
                                  final isInCart = state.cart.any(
                                    (item) => item.productId == prod.id,
                                  );

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: state.bgSecondary,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.06),
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: InkWell(
                                      onTap: isOutOfStock
                                          ? null
                                          : () {
                                              state.addCartItem(prod);
                                            },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        children: [
                                          if (isInCart)
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: themeColor,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                          // Product Layout
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              children: [
                                                // Image on the left
                                                Container(
                                                  width: 68,
                                                  height: 68,
                                                  decoration: BoxDecoration(
                                                    color: state.bgPrimary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child:
                                                      _buildHorizontalProductImage(
                                                        prod,
                                                        68,
                                                      ),
                                                ),
                                                const SizedBox(width: 10),

                                                // Details on the right
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        prod.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.outfit(
                                                              color: state
                                                                  .textPrimary,
                                                              fontSize: 13.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              height: 1.1,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        prod
                                                                .description
                                                                .isNotEmpty
                                                            ? prod.description
                                                            : prod.category,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: GoogleFonts.inter(
                                                          color: state
                                                              .textSecondary,
                                                          fontSize: 10.5,
                                                          height: 1.2,
                                                        ),
                                                      ),
                                                      Text(
                                                        _formatCurrency(
                                                          prod.sellingPrice,
                                                        ),
                                                        style:
                                                            GoogleFonts.inter(
                                                              color:
                                                                  const Color(
                                                                    0xFF3B82F6,
                                                                  ),
                                                              fontSize: 13.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Out of stock overlay
                                          if (isOutOfStock)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.redAccent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'RUPTURE',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          // ==========================================
          // TOGGLE CART BUTTON SEPARATOR
          // ==========================================
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isCartVisible = !_isCartVisible;
                });
              },
              child: Container(
                width: 44,
                decoration: BoxDecoration(
                  color: state.bgSecondary,
                  border: Border(
                    left: BorderSide(color: Colors.white.withOpacity(0.05)),
                    right: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isCartVisible
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_back_rounded,
                            color: themeColor,
                            size: 24,
                          ),
                        ),
                        if (!_isCartVisible) ...[
                          const SizedBox(height: 32),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.shopping_basket_rounded,
                                color: themeColor,
                                size: 28,
                              ),
                              if (state.cart.isNotEmpty)
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${state.cart.length}',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ==========================================
          // RIGHT SIDE: THE SALES REGISTER / CHECKOUT CART
          // ==========================================
          if (_isCartVisible)
            Container(
              width: 440,
              decoration: BoxDecoration(
                color: state.bgSecondary,
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cart Header with Patient Selector
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: state.bgPrimary.withOpacity(0.3),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_basket_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Panier Actif',
                              style: GoogleFonts.outfit(
                                color: state.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            TextButton(
                              onPressed: () {
                                state.clearCart();
                                _discountController.clear();
                                _cashReceivedController.clear();
                              },
                              child: Text(
                                'Vider',
                                style: GoogleFonts.inter(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Cart list items
                  Expanded(
                    child: state.cart.isEmpty
                        ? Container(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_checkout_rounded,
                                    color: state.textSecondaryLight.withOpacity(
                                      0.2,
                                    ),
                                    size: 64,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Panier Vide',
                                    style: GoogleFonts.outfit(
                                      color: state.textSecondaryLight
                                          .withOpacity(0.5),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Cliquez sur un produit à gauche pour l\'ajouter.',
                                    style: GoogleFonts.inter(
                                      color: state.textSecondaryLight
                                          .withOpacity(0.4),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: state.cart.length,
                            separatorBuilder: (context, idx) =>
                                Divider(color: state.borderTheme),
                            itemBuilder: (context, index) {
                              final item = state.cart[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: GoogleFonts.inter(
                                              color: state.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            '${_formatCurrency(item.unitPrice)} / u',
                                            style: GoogleFonts.inter(
                                              color: state.textSecondaryLight,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quantity editor buttons
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.remove_circle_outline_rounded,
                                            color: state.textSecondaryLight
                                                .withOpacity(0.5),
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            state.updateCartItemQuantity(
                                              item.productId,
                                              item.quantity - 1,
                                            );
                                          },
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: GoogleFonts.inter(
                                            color: state.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.add_circle_outline_rounded,
                                            color: themeColor,
                                            size: 18,
                                          ),
                                          onPressed: () =>
                                              state.updateCartItemQuantity(
                                                item.productId,
                                                item.quantity + 1,
                                              ),
                                        ),
                                      ],
                                    ),

                                    // Total item price
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        _formatCurrency(item.total),
                                        textAlign: TextAlign.end,
                                        style: GoogleFonts.inter(
                                          color: state.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),

                                    IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: Colors.redAccent,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        state.removeCartItem(item.productId);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Register payment summary panel
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: state.bgPrimary,
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Net Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NET À PAYER',
                              style: GoogleFonts.outfit(
                                color: state.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              _formatCurrency(netTotal),
                              style: GoogleFonts.outfit(
                                color: themeColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Payment method selector
                        Row(
                          children: [
                            _paymentBtn(
                              'ESPECES',
                              Icons.payments_rounded,
                              themeColor,
                              state,
                            ),
                            const SizedBox(width: 8),
                            _paymentBtn(
                              'ORANGE MONEY',
                              Icons.phone_android_rounded,
                              themeColor,
                              state,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Validation Button - Traiter le paiement
                        ElevatedButton(
                          onPressed: state.cart.isEmpty
                              ? null
                              : () {
                                  final success = state.checkoutCart(
                                    _paymentMethod,
                                    netTotal,
                                    0.0,
                                  );
                                  if (success) {
                                    final lastSale = state.sales[0];
                                    _showReceiptDialog(context, lastSale);
                                    _discountController.clear();
                                    _cashReceivedController.clear();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            disabledBackgroundColor: const Color(0xFF334155),
                          ),
                          child: Text(
                            'Traiter le paiement',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
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
    );
  }

  // Compact payment method button (Espèces / Crédit / Orange Money)
  Widget _paymentBtn(
    String method,
    IconData icon,
    Color themeColor,
    AppStateProvider state,
  ) {
    final isSelected = _paymentMethod == method;
    // Pick label shown on button
    final label = method == 'ESPECES' ? 'Espèces' : 'Orange Money';

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? themeColor.withOpacity(0.15) : state.bgPrimary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? themeColor : Colors.white.withOpacity(0.06),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? themeColor : state.textSecondaryLight,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: isSelected ? themeColor : state.textSecondaryLight,
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Printable Virtual Receipt Dialog
  void _showReceiptDialog(BuildContext context, Sale sale) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: state.bgSecondary,
          content: Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo in virtual receipt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      state.pharmacyLogo != null
                          ? Image.memory(
                              state.pharmacyLogo!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Color(0xFF0D9488),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 14,
                                      color: Colors.white,
                                    ),
                                    Container(
                                      width: 14,
                                      height: 4,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      SizedBox(width: 8),
                      Text(
                        state.pharmacyName.toUpperCase(),
                        style: GoogleFonts.courierPrime(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${state.pharmacyQuartier}\nTel: ${state.pharmacyContact2.isNotEmpty ? "${state.pharmacyContact1} / ${state.pharmacyContact2}" : state.pharmacyContact1}\nNIF: 998274-A',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.courierPrime(
                      color: Colors.black,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),
                  Text(
                    'REÇU DE PAIEMENT\nN°: ${sale.id}\nDate: ${DateFormat("dd/MM/yyyy HH:mm").format(sale.date)}\n${(sale.cashierName.toLowerCase().contains("admin") || sale.cashierName.toLowerCase().contains("responsable") || state.users.any((u) => u.role == "ADMIN" && (u.username.toLowerCase() == sale.cashierName.toLowerCase() || u.fullName.toLowerCase() == sale.cashierName.toLowerCase()))) ? "Admin" : "Caissier"}: ${sale.cashierName}\nClient: ${sale.patientName ?? "Passage"}',
                    style: GoogleFonts.courierPrime(
                      color: Colors.black,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),

                  // Items lines
                  ...sale.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: GoogleFonts.courierPrime(
                                    color: Colors.black,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '   ${item.quantity} x ${NumberFormat.decimalPattern('fr').format(item.unitPrice)} GNF',
                                style: GoogleFonts.courierPrime(
                                  color: Colors.black,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${NumberFormat.decimalPattern('fr').format(item.total)} GNF',
                                style: GoogleFonts.courierPrime(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),

                  // Calculations
                  if (sale.discountAmount > 0)
                    _receiptRow(
                      'REMISE APPLIQUÉE',
                      '- ${NumberFormat.decimalPattern('fr').format(sale.discountAmount)}',
                    ),

                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),

                  // Net Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL NET PAYÉ',
                        style: GoogleFonts.courierPrime(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${NumberFormat.decimalPattern('fr').format(sale.netAmount)} GNF',
                        style: GoogleFonts.courierPrime(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  _receiptRow('MODE DE PAIEMENT', sale.paymentMethod),

                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Signature',
                            style: GoogleFonts.courierPrime(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(height: 35),
                          Text(
                            '........................',
                            style: GoogleFonts.courierPrime(
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Merci de votre confiance !\nOn vous souhaite prompt rétablissement.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.courierPrime(
                      color: Colors.black,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Fermer',
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _exportInvoice(sale);
              },
              icon: Icon(Icons.share_rounded, size: 18),
              label: Text(
                'Exporter',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _printInvoice(sale);
              },
              icon: Icon(Icons.print_rounded, size: 18),
              label: Text(
                'Imprimer Facture',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11),
          ),
          Text(
            '$value GNF',
            style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Future<void> _printInvoice(Sale sale) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    await InvoicePrinter.printInvoice(
      sale,
      state.pharmacyLogo,
      pharmacyName: state.pharmacyName,
      quartier: state.pharmacyQuartier,
      contact1: state.pharmacyContact1,
      contact2: state.pharmacyContact2,
    );
  }

  Future<void> _exportInvoice(Sale sale) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    await InvoicePrinter.printInvoice(
      sale,
      state.pharmacyLogo,
      pharmacyName: state.pharmacyName,
      quartier: state.pharmacyQuartier,
      contact1: state.pharmacyContact1,
      contact2: state.pharmacyContact2,
      share: true,
    );
  }
}
