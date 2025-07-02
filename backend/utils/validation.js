/**
 * Validates product data.
 * @param {object} product
 * @param {boolean} isUpdate
 * @returns {string|null}
 */
const validateProduct = (product) => {
    const { PRODUCTNAME, PRICE, STOCK } = product;

    if (!PRODUCTNAME || PRODUCTNAME.trim() === '') {
        return 'Product name cannot be empty.';
    }
    if (PRICE === undefined || isNaN(PRICE) || parseFloat(PRICE) <= 0) {
        return 'Price must be a positive number.';
    }
    if (STOCK === undefined || isNaN(STOCK) || parseInt(STOCK) < 0) {
        return 'Stock must be a non-negative integer.';
    }
    return null;
};

module.exports = {
    validateProduct
};