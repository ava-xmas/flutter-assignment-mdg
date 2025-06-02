#include "crow.h"
#include <sqlite3.h>
#include <iostream>
#include <string>
#include "bcrypt/BCrypt.hpp"

// creating db and tables
//
static bool createDBAndTables(const char *dbName)
{
    sqlite3 *db;
    char *errMsg = nullptr;

    int exit = sqlite3_open(dbName, &db);

    if (exit != SQLITE_OK)
    {
        std::cerr << "cannot open database: " << sqlite3_errmsg(db) << std::endl;
        return false;
    }

    const char *sql_users = R"(
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            is_admin INTEGER NOT NULL DEFAULT 0,
            password TEXT NOT NULL
        );
    )";

    const char *sql_books = R"(
        CREATE TABLE IF NOT EXISTS books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            image_url TEXT,
            summary TEXT
        );
    )";

    const char *sql_reviews = R"(
        CREATE TABLE IF NOT EXISTS reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            book_id INTEGER NOT NULL,
            rating INTEGER NOT NULL,
            comment TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id),
            FOREIGN KEY(book_id) REFERENCES books(id)
        );
    )";

    if (sqlite3_exec(db, sql_users, nullptr, 0, &errMsg) != SQLITE_OK)
    {
        std::cerr << "failed to create users table: " << errMsg << std::endl;
        sqlite3_free(errMsg);
    }

    if (sqlite3_exec(db, sql_books, nullptr, 0, &errMsg) != SQLITE_OK)
    {
        std::cerr << "failed to create books table: " << errMsg << std::endl;
        sqlite3_free(errMsg);
    }

    if (sqlite3_exec(db, sql_reviews, nullptr, 0, &errMsg) != SQLITE_OK)
    {
        std::cerr << "failed to create reviews table: " << errMsg << std::endl;
        sqlite3_free(errMsg);
    }

    sqlite3_close(db);
    std::cout << "database and tables created successfully.\n";
    return true;
}

// opening db
//
sqlite3 *openDB(const char *dbName)
{
    sqlite3 *db;
    if (sqlite3_open(dbName, &db) != SQLITE_OK)
    {
        std::cerr << "error in opening db:" << sqlite3_errmsg(db) << std::endl;
        return nullptr;
    }
    return db;
}

// hashing passwords
//
std::string hashPassword(const std::string &password)
{
    return BCrypt::generateHash(password);
}

// verifying passwords
//
bool verifyPassword(const std::string &password, const std::string &hash)
{
    return BCrypt::validatePassword(password, hash);
}

// checking if user already exists in db ( for register )
bool storeUser(const std::string &username, const std::string &email, const std::string &hashedPassword)
{
    sqlite3 *db;
    int exit = sqlite3_open("book_review.sqlite", &db);
    if (exit)
    {
        sqlite3_close(db);
        return false;
    }

    sqlite3_stmt *stmt;
    const char *sql = "INSERT INTO users (username, email, password) VALUES (?, ?, ?);";

    exit = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
    if (exit != SQLITE_OK)
    {
        sqlite3_close(db);
        return false;
    }

    sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, email.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 3, hashedPassword.c_str(), -1, SQLITE_TRANSIENT);

    exit = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    sqlite3_close(db);

    return exit == SQLITE_DONE;
}

// checking if user doesnt exist in db ( for signup )
bool verifyUser(const std::string &username, const std::string &password)
{
    // fetch hashed password from db for username
    sqlite3 *db;
    int exit = sqlite3_open("book_review.sqlite", &db);

    if (exit)
    {
        sqlite3_close(db);
        return false;
    }

    sqlite3_stmt *stmt;
    const char *sql = "SELECT password FROM users WHERE username = ?;";

    exit = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);

    if (exit != SQLITE_OK)
    {
        sqlite3_close(db);
        return false;
    }

    sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);

    exit = sqlite3_step(stmt);
    if (exit != SQLITE_ROW)
    {
        sqlite3_finalize(stmt);
        sqlite3_close(db);
        return false;
    }

    const unsigned char *hashedPassword = sqlite3_column_text(stmt, 0);
    std::string storedHash = std::string(reinterpret_cast<const char *>(hashedPassword));

    sqlite3_finalize(stmt);
    sqlite3_close(db);

    return verifyPassword(password, storedHash);
}

// main
int main()
{
    // init db
    if (!createDBAndTables("book_review.sqlite"))
    {
        return 1;
    }

    // crow backend

    crow::SimpleApp app;

    // defining an endpoint in the root dir
    CROW_ROUTE(app, "/")([]()
                         { return "Book review backend is running!!"; });

    CROW_ROUTE(app, "/register").methods(crow::HTTPMethod::POST)([](const crow::request &req)
                                                                 {
        auto body = crow::json::load(req.body);
        if (!body) return crow::response(400, "Invalid JSON");

        std::string username = body["username"].s();
        std::string email = body["email"].s();
        std::string password = body["password"].s();

        if (username.empty() || email.empty() || password.empty()) {
            return crow::response(400, "Missing username or password");
        }

        std::string hashed = hashPassword(password); 
        
        if (!storeUser(username, email, hashed)) {
            return crow::response(400, "User already exists");
        }

        // create user
        return crow::response(200, "User registered"); });

    CROW_ROUTE(app, "/login").methods(crow::HTTPMethod::POST)([](const crow::request &req)
                                                              {
        auto body = crow::json::load(req.body);
        if (!body) return crow::response(400, "Invalid JSON");

        std::string username = body["username"].s();
        std::string email = body["email"].s();
        std::string password = body["password"].s();

        if (username.empty() || email.empty() || password.empty()) {
            return crow::response(400, "Missing username or password");
        }

        if (verifyUser(username, password)) {
            return crow::response(200, "Login successful");
        } else {
            return crow::response(401, "Invalid username or password");
        } });

    // set the port, set the app to run on multiple threads, and run the app
    app.port(18080)
        .multithreaded()
        .run();
}
