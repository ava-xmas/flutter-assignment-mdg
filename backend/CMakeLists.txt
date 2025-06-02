# find_package(Crow)
# target_link_libraries(backend PUBLIC Crow::crow)

# # cmake_minimum_required(VERSION 3.10)
# # project(crow_crud_auth)

# # set(CMAKE_CXX_STANDARD 17)

# # find_package(SQLite3 REQUIRED)
# # include_directories(${SQLite3_INCLUDE_DIRS})

# # add_executable(crow_crud_auth main.cpp)
# # target_link_libraries(crow_crud_auth ${SQLite3_LIBRARIES})

cmake_minimum_required(VERSION 3.10)
project(backend)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add Crow include directory
include_directories(/usr/include)  # Adjust if your crow headers are elsewhere

# Add executable target
add_executable(backend main.cpp)

# Link pthread and sqlite3
find_package(SQLite3 REQUIRED)
target_link_libraries(backend PUBLIC pthread SQLite::SQLite3)
