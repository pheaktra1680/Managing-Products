const { getConnection, sql } = require('../db');
const { validateProduct } = require('../utils/validation');

// Get all products
exports.getAllProducts = async (req, res) => {
    try {
        const pool = await getConnection();
        const result = await pool.request().query('SELECT * FROM PRODUCTS');
        res.status(200).json(result.recordset);
    } catch (err) {
        console.error('Error getting all products:', err);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get product by ID
exports.getProductById = async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await getConnection();
        const result = await pool.request()
            .input('PRODUCTID', sql.Int, id)
            .query('SELECT * FROM PRODUCTS WHERE PRODUCTID = @PRODUCTID');
        if (result.recordset.length > 0) {
            res.status(200).json(result.recordset[0]);
        } else {
            res.status(404).json({ message: 'Product not found' });
        }
    } catch (err) {
        console.error('Error getting product by ID:', err);
        res.status(500).json({ message: 'Server error' });
    }
};

// Create a new product
exports.createProduct = async (req, res) => {
    const { PRODUCTNAME, PRICE, STOCK } = req.body;
        console.log('Received request body:', req.body); // Add this line

    const validationError = validateProduct(req.body);
    if (validationError) {
        return res.status(400).json({ message: validationError });
    }

    try {
        const pool = await getConnection();
        const result = await pool.request()
            .input('PRODUCTNAME', sql.NVarChar, PRODUCTNAME)
            .input('PRICE', sql.Decimal(10, 2), PRICE)
            .input('STOCK', sql.Int, STOCK)
            .query('INSERT INTO PRODUCTS (PRODUCTNAME, PRICE, STOCK) VALUES (@PRODUCTNAME, @PRICE, @STOCK); SELECT SCOPE_IDENTITY() AS PRODUCTID;');

        const newProductId = result.recordset[0].PRODUCTID;
        res.status(201).json({ message: 'Product created successfully', productId: newProductId });
    } catch (err) {
        console.error('Error creating product:', err);
        res.status(500).json({ message: 'Server error' });
    }
};

// Update product by ID
exports.updateProduct = async (req, res) => {
    const { id } = req.params;
    const { PRODUCTNAME, PRICE, STOCK } = req.body;

    const validationError = validateProduct(req.body);
    if (validationError) {
        return res.status(400).json({ message: validationError });
    }

    try {
        const pool = await getConnection();
        const result = await pool.request()
            .input('PRODUCTID', sql.Int, id)
            .input('PRODUCTNAME', sql.NVarChar, PRODUCTNAME)
            .input('PRICE', sql.Decimal(10, 2), PRICE)
            .input('STOCK', sql.Int, STOCK)
            .query('UPDATE PRODUCTS SET PRODUCTNAME = @PRODUCTNAME, PRICE = @PRICE, STOCK = @STOCK WHERE PRODUCTID = @PRODUCTID');

        if (result.rowsAffected[0] > 0) {
            res.status(200).json({ message: 'Product updated successfully' });
        } else {
            res.status(404).json({ message: 'Product not found' });
        }
    } catch (err) {
        console.error('Error updating product:', err);
        res.status(500).json({ message: 'Server error' });
    }
};

// Delete product by ID
exports.deleteProduct = async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await getConnection();
        const result = await pool.request()
            .input('PRODUCTID', sql.Int, id)
            .query('DELETE FROM PRODUCTS WHERE PRODUCTID = @PRODUCTID');

        if (result.rowsAffected[0] > 0) {
            res.status(200).json({ message: 'Product deleted successfully' });
        } else {
            res.status(404).json({ message: 'Product not found' });
        }
    } catch (err) {
        console.error('Error deleting product:', err);
        res.status(500).json({ message: 'Server error' });
    }
};