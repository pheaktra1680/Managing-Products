import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String? _selectedSortOption; // To hold the currently selected sort option

  @override
  void initState() {
    super.initState();
    // Initialize ProductProvider's search controller reference
    Provider.of<ProductProvider>(context, listen: false).setSearchController(_searchController);

    // Initial fetch of products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });

    // Add listener to search controller for debouncing
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel(); // Cancel any active timer
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel(); // Cancel previous timer

    _debounce = Timer(const Duration(milliseconds: 500), () { // Debounce for 500ms
      _fetchProductsWithCurrentState(); // Use a helper to fetch with current search and sort
    });
  }

  // Helper method to fetch products maintaining current search and sort state
  Future<void> _fetchProductsWithCurrentState() async {
    await Provider.of<ProductProvider>(context, listen: false).fetchProducts(
      searchQuery: _searchController.text,
      sortOption: _selectedSortOption, // Pass the current sort option
    );
  }

  Future<void> _refreshProducts() async {
    // When refreshing, also clear the search bar and refetch all products
    _searchController.clear();
    _selectedSortOption = null; // Clear sort option on refresh
    await _fetchProductsWithCurrentState(); // Fetch with cleared state
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
        bottom: PreferredSize(
          // Adjusted height to accommodate a single row with padding
          preferredSize: const Size.fromHeight(kToolbarHeight + 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically in the center
              children: [
                Flexible(
                  flex: 2, // Give less space to the search bar to accommodate dropdown
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products by name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.black, width: 1),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Spacing between search bar and sort dropdown
                // Sort Dropdown
                Flexible(
                  flex: 0, // Give more relative space to the sort dropdown
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSortOption,
                      // Changed hint to display "Sort" and an icon
                      hint: const Row(
                        children: [
                          Icon(Icons.sort, color: Colors.black),
                          SizedBox(width: 4),
                          Text('Sort', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSortOption = newValue;
                        });
                        _fetchProductsWithCurrentState(); // Re-fetch with new sort option
                      },
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: null, // Value for "No Sort"
                          child: Text('No Sort'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'price_asc',
                          child: Text('Price: Low to High'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'price_desc',
                          child: Text('Price: High to Low'),
                        ),
                      ].map<DropdownMenuItem<String>>((DropdownMenuItem<String> item) {
                        return DropdownMenuItem<String>(
                          value: item.value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: item.child,
                          ),
                        );
                      }).toList(),
                      style: const TextStyle(color: Colors.black, fontSize: 14), // Text style for dropdown items
                      dropdownColor: Colors.white, // Background color of dropdown menu
                      // The selectedItemBuilder determines what is shown in the button itself
                      selectedItemBuilder: (BuildContext context) {
                        return <Widget>[
                          // For 'No Sort'
                          Row(
                            children: [
                              const Icon(Icons.sort, color: Colors.black),
                              const SizedBox(width: 4),
                              Text(
                                _selectedSortOption == null ? 'Sort' : '', // Display 'Sort' when nothing is selected
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                          // For 'Price: Low to High'
                          const Row(
                            children: [
                              Icon(Icons.sort, color: Colors.black),
                              SizedBox(width: 4),
                              Text('Low-High', style: TextStyle(color: Colors.black)), // Abbreviated
                            ],
                          ),
                          // For 'Price: High to Low'
                          const Row(
                            children: [
                              Icon(Icons.sort, color: Colors.black),
                              SizedBox(width: 4),
                              Text('High-Low', style: TextStyle(color: Colors.black)), // Abbreviated
                            ],
                          ),
                        ];
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          // Add Product Button
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (productProvider.errorMessage != null) {
            return Center(
              child: Text(
                'Error: ${productProvider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (productProvider.products.isEmpty && _searchController.text.isEmpty) {
            return const Center(
              child: Text('No products available. Add some!'),
            );
          }
          if (productProvider.products.isEmpty && _searchController.text.isNotEmpty) {
            return const Center(child: Text('No products found matching your search.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshProducts,
            child: ListView.builder(
              itemCount: productProvider.products.length,
              itemBuilder: (context, index) {
                final product = productProvider.products[index];
                return Card(
                  color: const Color.fromARGB(170, 255, 255, 255),
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 16),
                        // Product info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Price: \$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Stock: ${product.stock}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action buttons
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditProductScreen(product: product),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _confirmDelete(context, product);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        backgroundColor: Colors.white,
        content: Text(
          'Are you sure you want to delete ${product.productName}?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await Provider.of<ProductProvider>(
                context,
                listen: false,
              ).deleteProduct(product.productId!);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully!'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete product: ${Provider.of<ProductProvider>(context, listen: false).errorMessage}',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              elevation: 1,
              foregroundColor: Colors.red,
              backgroundColor: const Color.fromARGB(198, 255, 255, 255),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}