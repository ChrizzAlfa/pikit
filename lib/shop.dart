import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:pikit/cart.dart';
import 'package:pikit/login.dart';
import 'package:pikit/models/product_model.dart';
import 'package:pikit/models/product_stock_model.dart';
import 'package:pikit/theme/app_colors.dart';

class ShopPage extends StatefulWidget {
  final String outletAddress;
  final String outletId;

  const ShopPage({
    super.key, 
    required this.outletAddress, 
    required this.outletId
  });

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  // Storage and state management
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Product-related state
  List<ProductItem> _products = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String? _userId;

  bool _isAddingToCart = false;

  // Loading and error states
  bool _isLoading = true;
  String _errorMessage = '';

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentUser();
    _fetchProductsAndStock();
  }

  Future<void> _getCurrentUser() async {
  final userId = await _storage.read(key: 'user_id');
    setState(() {
      _userId = userId;
    });
  }

  Future<void> _addToCart(String productId) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add items to cart'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true; // Start loading
    });

    try {
      // Step 1: Fetch the product_stock record for this product in this outlet
      final stockResponse = await http.get(
        Uri.parse(
          'YOUR_POCKETBASE_URL/api/collections/product_stocks/records?filter=(product=%27$productId%27%26%26outlet=%27${widget.outletId}%27)'
        ),
      );

      if (stockResponse.statusCode != 200) {
        throw Exception('Failed to fetch product stock');
      }

      final stockData = json.decode(stockResponse.body);
      if (stockData['items'] == null || stockData['items'].isEmpty) {
        throw Exception('Product not available in this outlet');
      }

      final stockId = stockData['items'][0]['id'];

      // Step 2: Create a new cart_quantity record with default quantity of 1
      final cartQuantityResponse = await http.post(
        Uri.parse('YOUR_POCKETBASE_URL/api/collections/cart_quantity/records'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'product': stockId,
          'quantity': 1,
        }),
      );

      if (cartQuantityResponse.statusCode != 200) {
        throw Exception('Failed to create cart quantity record');
      }

      final cartQuantityData = json.decode(cartQuantityResponse.body);
      final cartQuantityId = cartQuantityData['id'];

      // Step 3: Update the user's cart with the new cart_quantity ID
      final response = await http.patch(
        Uri.parse('YOUR_POCKETBASE_URL/api/collections/users/records/$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cart+': cartQuantityId, // Using the + operator to append to the array
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added to cart'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to update cart');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingToCart = false; // Stop loading
      });
    }
  }

  Future<void> _fetchProductsAndStock() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First fetch all products
      final productsResponse = await http.get(
        Uri.parse('YOUR_POCKETBASE_URL/api/collections/products/records'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      // Then fetch product stocks for this specific outlet
      final stockResponse = await http.get(
        Uri.parse('YOUR_POCKETBASE_URL/api/collections/product_stocks/records?outlet=${widget.outletId}'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (productsResponse.statusCode == 200 && stockResponse.statusCode == 200) {
        final productsData = json.decode(productsResponse.body);
        final stockData = json.decode(stockResponse.body);

        final productModel = ProductModel.fromJson(productsData);
        final productStockModel = ProductStock.fromJson(stockData);

        // Filter products based on available stock in this outlet
        final availableProductIds = productStockModel.items
            ?.where((stockItem) => 
              stockItem.outlet == widget.outletId && 
              (stockItem.quantity ?? 0) > 0
            )
            .map((stockItem) => stockItem.product)
            .toList() ?? [];

        setState(() {
          // Only keep products that have stock in this outlet
          _products = productModel.items
              ?.where((product) => availableProductIds.contains(product.id))
              .toList() ?? [];
          
          // Store product stocks for potential future use

          // Generate categories from filtered products
          _categories = ['All'] + _products.map((item) => item.category!).toSet().toList();
          
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load products or stock: ${productsResponse.statusCode}, ${stockResponse.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch products. Please check your connection. ${e.toString()}';
      });
    }
  }

  // Logout method (unchanged from previous implementation)
  Future<void> _logout() async {
    try {
      await _storage.deleteAll();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Filtered products based on category and search
  List<ProductItem> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || 
        product.name!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Generate image URL for products (unchanged)
  String _getImageUrl(ProductItem product) {
    return 'YOUR_POCKETBASE_URL/api/files/${product.collectionName}/${product.id}/${product.picture}';
  }

  // Improved product fetching method
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('YOUR_POCKETBASE_URL/api/collections/products/records'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final productModel = ProductModel.fromJson(data);

        setState(() {
          _products = productModel.items ?? [];
          _categories = ['All'] + _products.map((item) => item.category!).toSet().toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch products. Please check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }

    // Use IndexedStack to switch between views
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildShopView(), // Your existing shop view
        CartPage(outletId: widget.outletId), // The new cart page
      ],
    );
  }

  Widget _buildShopView() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24)
          ),
          child: Column(
            children: [
              _buildSearchBar(),
              _buildOutletAddress(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildCategoryList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _buildProductGrid(),
        const SizedBox(height: 4)
      ],
    );
  }

  Widget _buildOutletAddress() {
    return Padding(
      padding: const EdgeInsets.only(left:20, right: 20, bottom: 8),
      child: Text(
        widget.outletAddress, // Display the outlet address
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.accent,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage, 
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 16, top: 40),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products',
                hintStyle: TextStyle(
                  color: AppColors.primary.withOpacity(0.5)
                ),
                filled: true,
                fillColor: AppColors.secondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0), // Change the radius here
                  borderSide: BorderSide.none, // No border line
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0), // Change the radius here
                  borderSide: BorderSide.none, // No border line
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0), // Change the radius here
                  borderSide: BorderSide.none, // No border line
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.accent),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent.withOpacity(0.05) : AppColors.accent.withOpacity(0.05), // Set color to transparent if selected
                border: isSelected ? Border.all(color: AppColors.accent) : null, // Only show border if selected
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.accent, // You can change this if you want different colors
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    final productsToShow = _filteredProducts;

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _fetchProductsAndStock,
        color: AppColors.accent,
        backgroundColor: AppColors.secondary,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.primary,
          ),
          
          child: productsToShow.isEmpty
              ? const Center(
                  child: Text(
                    'No products found', 
                    style: TextStyle(color: AppColors.accent),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: productsToShow.length,
                  itemBuilder: (context, index) {
                    final product = productsToShow[index];
                    return _buildProductCard(product);
                  },
                ),
        ),
      ),
    );
  }

Widget _buildProductCard(ProductItem product) {
  final formattedPrice = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(product.price);
  
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    color: AppColors.accent.withOpacity(0.05),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
            child: Image.network(
              _getImageUrl(product),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => 
                const Center(
                  child: Icon(
                    Icons.error, 
                    color: Colors.red, 
                    size: 50,
                  ),
                ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900, 
                        color: AppColors.accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondary
                      ),
                    ),
                  ],
                ),
              ),
              _isAddingToCart
                ? const CircularProgressIndicator(color: AppColors.accent)
                : IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: AppColors.accent),
                    onPressed: () async {
                      _addToCart(product.id!);
                    },
                  ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex, // Set the current index
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, color: AppColors.accent, size: 40),
            label: ''
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart, color: AppColors.accent, size: 40),
            label: ''
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Update the selected index
          });
        },
      ),
    );
  }
}