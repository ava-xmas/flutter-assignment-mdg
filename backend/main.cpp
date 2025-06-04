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

    // registration
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

    // login
    CROW_ROUTE(app, "/login").methods(crow::HTTPMethod::POST)([](const crow::request &req)
                                                              {
        auto body = crow::json::load(req.body);
        if (!body) return crow::response(400, "Invalid JSON");

        std::string username = body["username"].s();
        std::string password = body["password"].s();

        if (username.empty() || password.empty()) {
            return crow::response(400, "Missing username or password");
        }

        if (verifyUser(username, password)) {
            return crow::response(200, "Login successful");
        } else {
            return crow::response(401, "Invalid username or password");
        } });

    // getting all books
    CROW_ROUTE(app, "/books").methods(crow::HTTPMethod::GET)([](const crow::request &req, crow::response &res)
                                                             {
    sqlite3* db = openDB("book_review.sqlite");
    if (!db) {
        res.code = 500;
        res.write("failed to open database.");
        res.end();
        return;
    }

    const char* sql = "SELECT id, title, summary, image_url FROM books;";
    sqlite3_stmt* stmt = nullptr;

    if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) != SQLITE_OK) {
        sqlite3_close(db);
        res.code = 500;
        res.write("failed to prepare statement.");
        res.end();
        return;
    }

    crow::json::wvalue books = crow::json::wvalue::list();
    int index = 0;

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        crow::json::wvalue book;
        book["id"] = sqlite3_column_int(stmt, 0);

        const char* title = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
        book["title"] = title ? title : "";

        const char* summary = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2));
        book["summary"] = summary ? summary : "";

        const char* image = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 3));
        book["image"] = image ? image : "";

        books[index++] = std::move(book);
    }

    sqlite3_finalize(stmt);
    sqlite3_close(db);

    res.set_header("Content-Type", "application/json");
    res.code = 200;
    res.write(books.dump());
    res.end(); });

    // getting all reviews on a book
    CROW_ROUTE(app, "/books/<int>/reviews").methods(crow::HTTPMethod::GET)([](const crow::request &req, crow::response &res, int book_id)
                                                                           {
            sqlite3* db = openDB("book_review.sqlite");
            if (!db) {
                res.code = 500;
                res.write("database error");
                res.end();
                return;
            }
    
            const char* sql = R"(
                SELECT r.rating, r.comment, u.username
                FROM reviews r
                JOIN users u ON r.user_id = u.id
                WHERE r.book_id = ?;
            )";
    
            sqlite3_stmt* stmt = nullptr;
            if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) != SQLITE_OK) {
                sqlite3_close(db);
                res.code = 500;
                res.write("failed to prepare statement");
                res.end();
                return;
            }
    
            sqlite3_bind_int(stmt, 1, book_id);
    
            crow::json::wvalue reviews = crow::json::wvalue::list();
            int index = 0;
    
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                crow::json::wvalue review;
                review["rating"] = sqlite3_column_int(stmt, 0);
    
                const char* comment_text = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
                review["comment"] = comment_text ? comment_text : "";
    
                const char* username_text = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2));
                review["username"] = username_text ? username_text : "";
    
                reviews[index++] = std::move(review);
            }
    
            sqlite3_finalize(stmt);
            sqlite3_close(db);
    
            res.set_header("Content-Type", "application/json");
            res.code = 200;
            res.write(reviews.dump());
            res.end(); });

    // post a review on a selected book
    CROW_ROUTE(app, "/books/<int>/review").methods(crow::HTTPMethod::POST)([](const crow::request &req, crow::response &res, int book_id)
                                                                           {
            auto body = crow::json::load(req.body);
            if (!body)
            {
                res.code = 400;
                res.write("invalid JSON");
                return res.end();
            }
    
            std::string username = body["username"].s();
            int rating = body["rating"].i();
            std::string comment = body["comment"].s();
    
            if (username.empty() || rating < 1 || rating > 5)
            {
                res.code = 400;
                res.write("invalid input");
                return res.end();
            }
    
            sqlite3* db = openDB("book_review.sqlite");
            if (!db)
            {
                res.code = 500;
                res.write("database error");
                return res.end();
            }
    
            sqlite3_stmt* stmt;
            const char* sql_user = "SELECT id FROM users WHERE username = ?;";
            if (sqlite3_prepare_v2(db, sql_user, -1, &stmt, nullptr) != SQLITE_OK)
            {
                sqlite3_close(db);
                res.code = 500;
                res.write("failed to prepare statement");
                return res.end();
            }
    
            sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
            int rc = sqlite3_step(stmt);
            if (rc != SQLITE_ROW)
            {
                sqlite3_finalize(stmt);
                sqlite3_close(db);
                res.code = 404;
                res.write("user not found");
                return res.end();
            }
    
            int user_id = sqlite3_column_int(stmt, 0);
            sqlite3_finalize(stmt);
    
            const char* sql_insert = "INSERT INTO reviews (user_id, book_id, rating, comment) VALUES (?, ?, ?, ?);";
            if (sqlite3_prepare_v2(db, sql_insert, -1, &stmt, nullptr) != SQLITE_OK)
            {
                sqlite3_close(db);
                res.code = 500;
                res.write("failed to prepare insert statement");
                return res.end();
            }
    
            sqlite3_bind_int(stmt, 1, user_id);
            sqlite3_bind_int(stmt, 2, book_id);
            sqlite3_bind_int(stmt, 3, rating);
            sqlite3_bind_text(stmt, 4, comment.c_str(), -1, SQLITE_TRANSIENT);
    
            rc = sqlite3_step(stmt);
            sqlite3_finalize(stmt);
            sqlite3_close(db);
    
            if (rc != SQLITE_DONE)
            {
                res.code = 500;
                res.write("failed to add review");
                return res.end();
            }
    
            res.code = 200;
            res.write("review added successfully");
            return res.end(); });

    // editing review
    CROW_ROUTE(app, "/reviews/<int>/edit").methods(crow::HTTPMethod::PUT)([](const crow::request &req, crow::response &res, int review_id)
                                                                          {
            auto body = crow::json::load(req.body);
            if (!body)
            {
                res.code = 400;
                res.write("invalid JSON");
                return res.end();
            }
    
            std::string username = body["username"].s();
            int rating = body["rating"].i();
            std::string comment = body["comment"].s();
    
            if (username.empty() || rating < 1 || rating > 5)
            {
                res.code = 400;
                res.write("invalid input");
                return res.end();
            }
    
            sqlite3* db = openDB("book_review.sqlite");
            if (!db)
            {
                res.code = 500;
                res.write("database error");
                return res.end();
            }
    
            sqlite3_stmt* stmt;
            const char* sql_user = "SELECT id FROM users WHERE username = ?;";
            if (sqlite3_prepare_v2(db, sql_user, -1, &stmt, nullptr) != SQLITE_OK)
            {
                sqlite3_close(db);
                res.code = 500;
                res.write("failed to prepare user query");
                return res.end();
            }
    
            sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
            if (sqlite3_step(stmt) != SQLITE_ROW)
            {
                sqlite3_finalize(stmt);
                sqlite3_close(db);
                res.code = 404;
                res.write("user not found");
                return res.end();
            }
    
            int user_id = sqlite3_column_int(stmt, 0);
            sqlite3_finalize(stmt);
    
            const char* sql_check = "SELECT user_id FROM reviews WHERE id = ?;";
            if (sqlite3_prepare_v2(db, sql_check, -1, &stmt, nullptr) != SQLITE_OK)
            {
                sqlite3_close(db);
                res.code = 500;
                res.write("failed to prepare ownership check");
                return res.end();
            }
    
            sqlite3_bind_int(stmt, 1, review_id);
            if (sqlite3_step(stmt) != SQLITE_ROW || sqlite3_column_int(stmt, 0) != user_id)
            {
                sqlite3_finalize(stmt);
                sqlite3_close(db);
                res.code = 403;
                res.write("forbidden: Not your review");
                return res.end();
            }
            sqlite3_finalize(stmt);
    
            const char* sql_update = "UPDATE reviews SET rating = ?, comment = ? WHERE id = ?;";
            if (sqlite3_prepare_v2(db, sql_update, -1, &stmt, nullptr) != SQLITE_OK)
            {
                sqlite3_close(db);
                res.code = 500;
                res.write("failed to prepare update");
                return res.end();
            }
    
            sqlite3_bind_int(stmt, 1, rating);
            sqlite3_bind_text(stmt, 2, comment.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(stmt, 3, review_id);
    
            int rc = sqlite3_step(stmt);
            sqlite3_finalize(stmt);
            sqlite3_close(db);
    
            if (rc != SQLITE_DONE)
            {
                res.code = 500;
                res.write("failed to update review");
                return res.end();
            }
    
            res.code = 200;
            res.write("review updated successfully");
            return res.end(); });

    // deleting review
    CROW_ROUTE(app, "/reviews/<int>/delete").methods(crow::HTTPMethod::DELETE)([](const crow::request &req, crow::response &res, int review_id)
                                                                               {
            auto body = crow::json::load(req.body);
            if (!body)
            {
                res.code = 400;
                res.write("invalid JSON");
                return res.end();
            }
    
            std::string username = body["username"].s();
            if (username.empty())
            {
                res.code = 400;
                res.write("username required");
                return res.end();
            }
    
            sqlite3* db = openDB("book_review.sqlite");
            if (!db)
            {
                res.code = 500;
                res.write("database error");
                return res.end();
            }
    
            sqlite3_stmt* stmt;
    
            // Get user_id
            const char* sql_user = "SELECT id FROM users WHERE username = ?;";
            if (sqlite3_prepare_v2(db, sql_user, -1, &stmt, nullptr) != SQLITE_OK)
            {
                sqlite3_close(db);
                res.code = 500;
                res.write("failed to prepare user lookup");
                return res.end();
            }
    
            sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
            if (sqlite3_step(stmt) != SQLITE_ROW)
            {
                sqlite3_finalize(stmt);
                sqlite3_close(db);
                res.code = 404;
                res.write("user not found");
                return res.end();
            }
            int user_id = sqlite3_column_int(stmt, 0);
            sqlite3_finalize(stmt);
    
            // Check ownership
            const char* sql_check = "SELECT user_id FROM reviews WHERE id = ?;";
            if (sqlite3_prepare_v2(db, sql_check, -1, &stmt, nullptr) != SQLITE_OK)
            {
                sqlite3_close(db);
                res.code = 500;
                res.write("failed to prepare ownership check");
                return res.end();
            }
    
            sqlite3_bind_int(stmt, 1, review_id);
            if (sqlite3_step(stmt) != SQLITE_ROW || sqlite3_column_int(stmt, 0) != user_id)
            {
                sqlite3_finalize(stmt);
                sqlite3_close(db);
                res.code = 403;
                res.write("forbidden: Not your review");
                return res.end();
            }
            sqlite3_finalize(stmt);
    
            // Delete review
            const char* sql_delete = "DELETE FROM reviews WHERE id = ?;";
            if (sqlite3_prepare_v2(db, sql_delete, -1, &stmt, nullptr) != SQLITE_OK)
            {
                sqlite3_close(db);
                res.code = 500;
                res.write("failed to prepare delete statement");
                return res.end();
            }
    
            sqlite3_bind_int(stmt, 1, review_id);
            int rc = sqlite3_step(stmt);
            sqlite3_finalize(stmt);
            sqlite3_close(db);
    
            if (rc != SQLITE_DONE)
            {
                res.code = 500;
                res.write("failed to delete review");
                return res.end();
            }
    
            res.code = 200;
            res.write("review deleted successfully");
            return res.end(); });

    // set the port, set the app to run on multiple threads, and run the app
    app.bindaddr("0.0.0.0").port(18080).run();
}
