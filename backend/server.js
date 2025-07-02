require('dotenv').config();
const app = require('./app');
const { getConnection } = require('./db');

const port = process.env.PORT || 3000;

// Start the server
const startServer = async () => {
    try {
        await getConnection();
        console.log('Database connected successfully!');

        app.listen(port, () => {
            console.log(`Server running on port ${port}`);
        });
    } catch (err) {
        console.error('Failed to start server due to database connection error:', err);
        process.exit(1);
    }
};

startServer();