#include "crow.h"
#include <sqlite3.h>

// databases

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

int main()
{
    // init db
    if (!createDBAndTables("book_review.sqlite"))
    {
        return 1;
    }

    crow::SimpleApp app;

    // defining an endpoint in the root dir
    CROW_ROUTE(app, "/")([]()
                         { return "Book review backend is running!!"; });

    // set the port, set the app to run on multiple threads, and run the app
    app.port(18080).multithreaded().run();
}
