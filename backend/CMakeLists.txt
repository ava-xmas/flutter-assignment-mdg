cmake_minimum_required(VERSION 3.10)
project(backend)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Crow headers (adjust path if installed elsewhere)
include_directories(/usr/include)

# bcrypt
include_directories(libbcrypt/include)
link_directories(libbcrypt/build)

# Find SQLite
find_package(SQLite3 REQUIRED)

# Build the executable
add_executable(backend main.cpp)

# Link libraries (use consistent keyword signature)
target_link_libraries(backend
    PUBLIC
    pthread
    SQLite::SQLite3
    bcrypt
)
