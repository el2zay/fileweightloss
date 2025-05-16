cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Nouvelle configuration pour les binaires externes
set(EXTERNAL_BIN_DIR "${CMAKE_SOURCE_DIR}/../assets/bin/windows")
file(GLOB EXTERNAL_BINS "${EXTERNAL_BIN_DIR}/*.exe" "${EXTERNAL_BIN_DIR}/*.dll")

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Copie des binaires dans le répertoire de sortie
add_custom_command(
  TARGET ${BINARY_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
  "${EXTERNAL_BIN_DIR}"
  "$<TARGET_FILE_DIR:${BINARY_NAME}>/data/flutter_assets/assets/bin/windows"
  COMMENT "Copying external binaries..."
)

# Configuration standard
apply_standard_settings(${BINARY_NAME})

# Définitions de version
target_compile_definitions(${BINARY_NAME} PRIVATE 
  "FLUTTER_VERSION=\"${FLUTTER_VERSION}\""
  "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}"
  "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}"
  "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}"
  "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}"
  NOMINMAX
)

# Configuration des dépendances
target_link_libraries(${BINARY_NAME} PRIVATE 
  flutter
  flutter_wrapper_app
  "dwmapi.lib"
)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
add_dependencies(${BINARY_NAME} flutter_assemble)
