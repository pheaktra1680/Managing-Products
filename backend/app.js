// app.js
const express = require('express');
const cors = require('cors');
const productRoutes = require('./routes/productRoutes');

const app = express();

app.use(express.json());
app.use(cors());

// Routes
app.use('/products', productRoutes);

app.use((req, res, next) => {
    res.status(404).json({ message: 'Route Not Found' });
});

app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ message: 'Something broke!' });
});

module.exports = app;