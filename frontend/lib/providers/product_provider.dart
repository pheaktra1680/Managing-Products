import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import 'package:flutter/widgets.dart'; // Import for TextEditingController

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<Product> _filteredProducts = []; // Corrected variable name from _filterProducts

  List<Product> get products => _filteredProducts; // Expose filtered products
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _baseUrl = 'http://10.0.2.2:3000';

  // Add a property to keep track of the current sort option
  String? _currentSortOption;

  // Add a reference to the search controller to maintain search state on refresh
  TextEditingController? _searchController;
  void setSearchController(TextEditingController controller) {
    _searchController = controller;
  }

  ProductProvider() {
    fetchProducts();
  }

  // Modified fetchProducts to accept optional searchQuery and sortOption
  Future<void> fetchProducts({String? searchQuery, String? sortOption}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Update the current sort option if a new one is provided
    if (sortOption != null) {
      _currentSortOption = sortOption;
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl/products'));
      if (response.statusCode == 200) {
        List<dynamic> productJson = json.decode(response.body);
        _products = productJson.map((json) => Product.fromJson(json)).toList();

        // 1. Apply Filtering (if searchQuery is provided)
        List<Product> tempProducts = List.from(_products);
        if (searchQuery != null && searchQuery.isNotEmpty) {
          tempProducts = tempProducts.where((product) {
            return product.productName.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();
        }

        // 2. Apply Sorting (based on _currentSortOption)
        if (_currentSortOption == 'price_asc') {
          tempProducts.sort((a, b) => a.price.compareTo(b.price));
        } else if (_currentSortOption == 'price_desc') {
          tempProducts.sort((a, b) => b.price.compareTo(a.price));
        }
        // You can add more sorting options here (e.g., by stock, by name) if needed

        _filteredProducts = tempProducts;

      } else {
        _errorMessage = 'Failed to load products: ${response.statusCode}';
        _filteredProducts = [];
      }
    } catch (e) {
      _errorMessage = 'Error fetching products: $e';
      _filteredProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 201) {
        // Re-fetch with current search and sort state after adding
        await fetchProducts(
          searchQuery: _searchController?.text,
          sortOption: _currentSortOption,
        );
        return true;
      } else {
        final errorBody = json.decode(response.body);
        _errorMessage = 'Failed to add product: ${errorBody['message'] ?? response.statusCode}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error adding product: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct(Product product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/products/${product.productId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 200) {
        // Re-fetch with current search and sort state after updating
        await fetchProducts(
          searchQuery: _searchController?.text,
          sortOption: _currentSortOption,
        );
        return true;
      } else {
        final errorBody = json.decode(response.body);
        _errorMessage = 'Failed to update product: ${errorBody['message'] ?? response.statusCode}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating product: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/products/$productId'),
      );

      if (response.statusCode == 200) {
        // Remove from both _products (original) and _filteredProducts (displayed)
        _products.removeWhere((product) => product.productId == productId);
        _filteredProducts.removeWhere((product) => product.productId == productId);
        notifyListeners();
        return true;
      } else {
        final errorBody = json.decode(response.body);
        _errorMessage = 'Failed to delete product: ${errorBody['message'] ?? response.statusCode}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting product: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}