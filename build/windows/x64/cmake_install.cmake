# Install script for directory: C:/Users/ahada/Documents/abdulahad/kivixa/windows

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "$<TARGET_FILE_DIR:kivixa>")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/flutter/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/connectivity_plus/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/desktop_drop/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/dynamic_color/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/flutter_secure_storage_windows/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/sqlite3_flutter_libs/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/url_launcher_windows/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/pdfrx/cmake_install.cmake")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xRuntimex" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/kivixa.exe")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug" TYPE EXECUTABLE FILES "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/kivixa.exe")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Pp][Rr][Oo][Ff][Ii][Ll][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/kivixa.exe")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile" TYPE EXECUTABLE FILES "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/kivixa.exe")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/kivixa.exe")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release" TYPE EXECUTABLE FILES "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/kivixa.exe")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xRuntimex" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/data/icudtl.dat")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/data" TYPE FILE FILES "C:/Users/ahada/Documents/abdulahad/kivixa/windows/flutter/ephemeral/icudtl.dat")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Pp][Rr][Oo][Ff][Ii][Ll][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/data/icudtl.dat")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/data" TYPE FILE FILES "C:/Users/ahada/Documents/abdulahad/kivixa/windows/flutter/ephemeral/icudtl.dat")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/data/icudtl.dat")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/data" TYPE FILE FILES "C:/Users/ahada/Documents/abdulahad/kivixa/windows/flutter/ephemeral/icudtl.dat")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xRuntimex" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/flutter_windows.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug" TYPE FILE FILES "C:/Users/ahada/Documents/abdulahad/kivixa/windows/flutter/ephemeral/flutter_windows.dll")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Pp][Rr][Oo][Ff][Ii][Ll][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/flutter_windows.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile" TYPE FILE FILES "C:/Users/ahada/Documents/abdulahad/kivixa/windows/flutter/ephemeral/flutter_windows.dll")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/flutter_windows.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release" TYPE FILE FILES "C:/Users/ahada/Documents/abdulahad/kivixa/windows/flutter/ephemeral/flutter_windows.dll")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xRuntimex" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/connectivity_plus_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/desktop_drop_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/dynamic_color_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/flutter_secure_storage_windows_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/sqlite3_flutter_libs_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/sqlite3.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/url_launcher_windows_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/pdfrx.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/pdfium.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug" TYPE FILE FILES
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/connectivity_plus/Debug/connectivity_plus_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/desktop_drop/Debug/desktop_drop_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/dynamic_color/Debug/dynamic_color_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/flutter_secure_storage_windows/Debug/flutter_secure_storage_windows_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/sqlite3_flutter_libs/Debug/sqlite3_flutter_libs_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/sqlite3_flutter_libs/Debug/sqlite3.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/url_launcher_windows/Debug/url_launcher_windows_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/pdfrx/shared/Debug/pdfrx.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/.lib/latest/x64/pdfium.dll"
      )
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Pp][Rr][Oo][Ff][Ii][Ll][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/connectivity_plus_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/desktop_drop_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/dynamic_color_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/flutter_secure_storage_windows_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/sqlite3_flutter_libs_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/sqlite3.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/url_launcher_windows_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/pdfrx.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/pdfium.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile" TYPE FILE FILES
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/connectivity_plus/Profile/connectivity_plus_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/desktop_drop/Profile/desktop_drop_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/dynamic_color/Profile/dynamic_color_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/flutter_secure_storage_windows/Profile/flutter_secure_storage_windows_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/sqlite3_flutter_libs/Profile/sqlite3_flutter_libs_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/sqlite3_flutter_libs/Profile/sqlite3.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/url_launcher_windows/Profile/url_launcher_windows_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/pdfrx/shared/Profile/pdfrx.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/.lib/latest/x64/pdfium.dll"
      )
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/connectivity_plus_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/desktop_drop_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/dynamic_color_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/flutter_secure_storage_windows_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/sqlite3_flutter_libs_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/sqlite3.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/url_launcher_windows_plugin.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/pdfrx.dll;C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/pdfium.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release" TYPE FILE FILES
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/connectivity_plus/Release/connectivity_plus_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/desktop_drop/Release/desktop_drop_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/dynamic_color/Release/dynamic_color_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/flutter_secure_storage_windows/Release/flutter_secure_storage_windows_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/sqlite3_flutter_libs/Release/sqlite3_flutter_libs_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/sqlite3_flutter_libs/Release/sqlite3.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/url_launcher_windows/Release/url_launcher_windows_plugin.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/plugins/pdfrx/shared/Release/pdfrx.dll"
      "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/.lib/latest/x64/pdfium.dll"
      )
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xRuntimex" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug" TYPE DIRECTORY FILES "C:/Users/ahada/Documents/abdulahad/kivixa/build/native_assets/windows/")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Pp][Rr][Oo][Ff][Ii][Ll][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile" TYPE DIRECTORY FILES "C:/Users/ahada/Documents/abdulahad/kivixa/build/native_assets/windows/")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release" TYPE DIRECTORY FILES "C:/Users/ahada/Documents/abdulahad/kivixa/build/native_assets/windows/")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xRuntimex" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    
  file(REMOVE_RECURSE "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/data/flutter_assets")
  
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Pp][Rr][Oo][Ff][Ii][Ll][Ee])$")
    
  file(REMOVE_RECURSE "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/data/flutter_assets")
  
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    
  file(REMOVE_RECURSE "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/data/flutter_assets")
  
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xRuntimex" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/data/flutter_assets")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Debug/data" TYPE DIRECTORY FILES "C:/Users/ahada/Documents/abdulahad/kivixa/build//flutter_assets")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Pp][Rr][Oo][Ff][Ii][Ll][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/data/flutter_assets")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/data" TYPE DIRECTORY FILES "C:/Users/ahada/Documents/abdulahad/kivixa/build//flutter_assets")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/data/flutter_assets")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/data" TYPE DIRECTORY FILES "C:/Users/ahada/Documents/abdulahad/kivixa/build//flutter_assets")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xRuntimex" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Pp][Rr][Oo][Ff][Ii][Ll][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/data/app.so")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Profile/data" TYPE FILE FILES "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/app.so")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/data/app.so")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
        message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
file(INSTALL DESTINATION "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/runner/Release/data" TYPE FILE FILES "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/app.so")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
file(WRITE "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
