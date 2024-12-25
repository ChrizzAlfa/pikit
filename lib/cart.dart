import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pikit/models/product_model.dart';
import 'dart:convert';
import 'package:pikit/models/user_model.dart';
import 'package:pikit/models/product_stock_model.dart';
import 'package:pikit/theme/app_colors.dart';

class CartPage extends StatefulWidget {
  final String outletId;

  const CartPage({super.key, required this.outletId});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  List<ProductStockItem> _cartItems = [];
  Map<String, ProductItem> _productDetails = {};
  Map<String, int> _cartQuantities = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String _userId = '';

  bool _isRemovingFromCart = false;
  bool _isProcessingCheckout = false;


  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentUser();
    await _fetchUserData();
  }

  Future<void> _processCheckout() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingCheckout = true;
    });

    try {
      // Step 1: Get user's cart items
      final userResponse = await http.get(
        Uri.parse('YOUR_POCKETBASE_URL/api/collections/users/records?filter=(id=%27$_userId%27)'),
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Failed to fetch user data');
      }

      final userData = json.decode(userResponse.body);
      if (userData['items'] == null || userData['items'].isEmpty) {
        throw Exception('No user data found');
      }

      final List<dynamic> cartIds = userData['items'][0]['cart'];

      // Step 2: Process each cart item
      for (var cartId in cartIds) {
        // Get cart quantity details
        final cartQuantityResponse = await http.get(
          Uri.parse('YOUR_POCKETBASE_URL/api/collections/cart_quantity/records/$cartId'),
        );

        if (cartQuantityResponse.statusCode != 200) continue;

        final cartQuantityData = json.decode(cartQuantityResponse.body);
        final String productStockId = cartQuantityData['product'];
        final int quantity = cartQuantityData['quantity'];

        // Update product stock
        final stockResponse = await http.get(
          Uri.parse('YOUR_POCKETBASE_URL/api/collections/product_stocks/records/$productStockId'),
        );

        if (stockResponse.statusCode != 200) continue;

        final stockData = json.decode(stockResponse.body);
        final int currentStock = stockData['quantity'];
        final int newStock = currentStock - quantity;

        if (newStock < 0) {
          throw Exception('Insufficient stock for product ${stockData['id']}');
        }

        // Update the stock in the database
        final updateResponse = await http.patch(
          Uri.parse('YOUR_POCKETBASE_URL/api/collections/product_stocks/records/$productStockId'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'quantity': newStock}),
        );

        if (updateResponse.statusCode != 200) {
          throw Exception('Failed to update stock for product ${stockData['id']}');
        }

        // Delete the cart quantity record
        await http.delete(
          Uri.parse('YOUR_POCKETBASE_URL/api/collections/cart_quantity/records/$cartId'),
        );
      }

      // Step 3: Clear user's cart
      final updateUserResponse = await http.patch(
        Uri.parse('YOUR_POCKETBASE_URL/api/collections/users/records/${userData['items'][0]['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'cart': []}),
      );

      if (updateUserResponse.statusCode != 200) {
        throw Exception('Failed to clear user cart');
      }

      // Success message and refresh
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkout successful!'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchUserData(); // Refresh the cart
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessingCheckout = false;
      });
    }
  }

  Future<ProductItem?> _fetchProductDetails(String productId) async {
    if (_productDetails.containsKey(productId)) {
      return _productDetails[productId];
    }

    try {
      final response = await http.get(
        Uri.parse('YOUR_POCKETBASE_URL/api/collections/products/records/$productId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final product = ProductItem.fromJson(data);
        _productDetails[productId] = product;
        return product;
      } else {
        throw Exception('Failed to load product details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching product details: $e');
      return null;
    }
  }

  Future<void> _getCurrentUser() async {
    final userId = await _storage.read(key: 'user_id');
    if (userId != null) {
      setState(() {
        _userId = userId;
      });
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('YOUR_POCKETBASE_URL/api/collections/users/records?filter=(id=%27$_userId%27)'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userModel = UserModel.fromJson(data);

        if (userModel.items != null && userModel.items!.isNotEmpty) {
          final cartItems = userModel.items!.first.cart ?? [];
          await _fetchProductStock(cartItems);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No items in the cart.';
          });
        }
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch user data. Please check your connection.';
        });
      }
    }
  }

  Future<void> _fetchProductStock(List<String> cart) async {
    List<ProductStockItem> matchingItems = [];
    Map<String, String> stockIds = {}; // Map to store product -> stockId mapping

    try {
      print('User ID: $_userId');

      // First, fetch cart quantities and get stock IDs
      for (String cartQuantityId in cart) {
        final cartResponse = await http.get(
          Uri.parse(
            'YOUR_POCKETBASE_URL/api/collections/cart_quantity/records/$cartQuantityId'
          ),
        );

        if (cartResponse.statusCode == 200) {
          final cartData = json.decode(cartResponse.body);
          // Store quantity and get the product stock ID
          String productStockId = cartData['product'] ?? '';
          int quantity = cartData['quantity'] ?? 0;
          
          if (productStockId.isNotEmpty) {
            _cartQuantities[productStockId] = quantity;
            stockIds[cartQuantityId] = productStockId;
          }
        }
      }
      // Then fetch product stock data using the collected stock IDs
      for (String stockId in stockIds.values) {
        final stockResponse = await http.get(
          Uri.parse(
            'YOUR_POCKETBASE_URL/api/collections/product_stocks/records?filter=(id=%27$stockId%27%26%26outlet=%27${widget.outletId}%27)'
          ),
        );

        if (stockResponse.statusCode == 200) {
          final stockData = json.decode(stockResponse.body);
          ProductStock productStock = ProductStock.fromJson(stockData);

          if (productStock.items != null && productStock.items!.isNotEmpty) {
            for (var item in productStock.items!) {
              // Set the quantity from cart_quantity collection
              if (_cartQuantities.containsKey(stockId)) {
                item.quantity = _cartQuantities[stockId];
                matchingItems.add(item);
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _cartItems = matchingItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchProductStock: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch product data. Please check your connection.';
        });
      }
    }
  }

  Future<void> _removeFromCart(String stockId) async {
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to remove items from cart'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isRemovingFromCart = true; // Start loading
    });

    try {
      // Step 1: Fetch the cart_quantity ID associated with the stock ID
      final cartQuantityResponse = await http.get(
        Uri.parse('YOUR_POCKETBASE_URL/api/collections/cart_quantity/records?filter=(product=%27$stockId%27)'),
      );

      if (cartQuantityResponse.statusCode == 200) {
        final cartQuantityData = json.decode(cartQuantityResponse.body);
        if (cartQuantityData['items'] != null && cartQuantityData['items'].isNotEmpty) {
          // Get the first cart_quantity ID
          String cartQuantityId = cartQuantityData['items'][0]['id'];

          // Step 2: Delete the cart_quantity record
          final deleteResponse = await http.delete(
            Uri.parse('YOUR_POCKETBASE_URL/api/collections/cart_quantity/records/$cartQuantityId'),
          );

          if (deleteResponse.statusCode == 204) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item removed from cart'),
                backgroundColor: Colors.green,
              ),
            );
            await _fetchUserData(); // Refresh the cart data
          } else {
            throw Exception('Failed to delete cart quantity');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cart quantity found for this product'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        throw Exception('Failed to fetch cart quantity');
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
        _isRemovingFromCart = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }

    return Container(
      child: _cartItems.isEmpty
          ? RefreshIndicator(
              onRefresh: _fetchUserData,
              color: AppColors.accent,
              child: ListView(
                children: const [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Your Cart is Empty',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchUserData,
              color: AppColors.accent,
              backgroundColor: AppColors.secondary,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return FutureBuilder<ProductItem?>(
                          future: _fetchProductDetails(item.product ?? ''),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.accent,
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return ListTile(
                                title: Text(
                                  'Error loading product: ${item.product}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                                leading: const Icon(Icons.error, color: Colors.red),
                              );
                            }

                            final product = snapshot.data!;
                            final formattedPrice = NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(product.price);

                            return _buildCartItemCard(product, item, formattedPrice);
                          },
                        );
                      },
                    ),
                  ),
                  _buildTotalAmount(),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalAmount() {
    double totalAmount = _calculateTotalAmount();
    final formattedTotal = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(totalAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.secondary,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              Text(
                formattedTotal,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessingCheckout ? null : _processCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessingCheckout
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'checkout',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Dirtyline'
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalAmount() {
    double total = 0.0;

    for (var item in _cartItems) {
      final productId = item.product ?? '';
      final product = _productDetails[productId];

      if (product != null) {
        total += (product.price! * (item.quantity ?? 0));
      }
    }
    return total;
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
            onPressed: _fetchUserData,
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

  Future<int> _getProductStock(String productStockId) async {
    try {
      // Step 1: Fetch user's cart
      final userResponse = await http.get(
        Uri.parse('YOUR_POCKETBASE_URL/api/collections/users/records?filter=(id=%27$_userId%27)'),
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        
        if (userData['items'] != null && 
            userData['items'].isNotEmpty && 
            userData['items'][0]['cart'] != null) {
          
          final List<dynamic> cartIds = userData['items'][0]['cart'];
          
          // Step 2: Iterate through cart IDs to find matching product
          for (String cartId in cartIds) {
            print('This is car ID $cartId');
            final cartQuantityResponse = await http.get(
              Uri.parse('YOUR_POCKETBASE_URL/api/collections/cart_quantity/records/$cartId'),
            );

            if (cartQuantityResponse.statusCode == 200) {
              final cartQuantityData = json.decode(cartQuantityResponse.body);
              
              // Check if this cart entry matches our product stock ID
              if (cartQuantityData['product'] == productStockId) {
                // Step 3: Fetch product stock data
                final stockResponse = await http.get(
                  Uri.parse('YOUR_POCKETBASE_URL/api/collections/product_stocks/records/$productStockId'),
                );

                if (stockResponse.statusCode == 200) {
                  final stockData = json.decode(stockResponse.body);
                  return stockData['quantity'] ?? 0;
                }
              }
            }
          }
        }
      }

      return 0;
    } catch (e) {
      print('Error fetching product stock: $e');
      return 0;
    }
  }

  Widget _buildCartItemCard(ProductItem product, ProductStockItem item, String formattedPrice) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildProductImage(product),
        trailing: _isRemovingFromCart
            ? const CircularProgressIndicator(color: AppColors.accent) // show loading indicator instead of the remove button
            : IconButton(
                icon: const Icon(Icons.remove_shopping_cart, color: AppColors.accent),
                onPressed: () => _removeFromCart(item.id ?? ''),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name ?? 'Unknown Product',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.accent,
              ),
            ),
            Text(
              formattedPrice,
              style: const TextStyle(color: AppColors.secondary),
            ),
            Text(
              'Quantity: ${item.quantity}',
              style: const TextStyle(color: AppColors.secondary),
            ),
            FutureBuilder<int>(
              future: _getProductStock(item.id ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    'Loading stock...',
                    style: TextStyle(color: AppColors.secondary),
                  );
                }
                return Text(
                  'Stock: ${snapshot.data ?? 0}',
                  style: const TextStyle(color: AppColors.secondary),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(ProductItem product) {
    if (product.picture != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          'YOUR_POCKETBASE_URL/api/files/${product.collectionId}/${product.id}/${product.picture}',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => 
            const Icon(Icons.image_not_supported, color: AppColors.accent),
        ),
      );
    } else {
      return const Icon(Icons.shopping_cart, color: AppColors.accent);
    }
  }
}