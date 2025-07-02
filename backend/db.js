const sql = require('mssql');
require('dotenv').config();

const config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_DATABASE,
    options: {
        encrypt: true,
        trustServerCertificate: true 
    }
};

async function getConnection() {
    try {
        let pool = await sql.connect(config);
        return pool;
    } catch (err) {
        console.error('Database connection failed!', err);
        throw err;
    }
}

module.exports = {
    sql,
    getConnection
};