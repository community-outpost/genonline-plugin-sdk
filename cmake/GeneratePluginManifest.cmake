# SPDX-License-Identifier: MIT
# Writes an unsigned plugin.manifest for a GenOnline plugin folder.
#
# cmake -DPLUGIN_DIR=<folder> -DPLUGIN_NAME=genonline_eos -DPLUGIN_VERSION=YYYY.MM.PATCH -DPLUGIN_API_VERSION=1 -P GeneratePluginManifest.cmake
#
# The manifest lists the size and the SHA256 of every file in the folder tree,
# except plugin.manifest and plugin.manifest.minisig in the folder itself. The
# format is the one GenOnlinePluginTrust in the GenOnline client reads. This
# script never signs anything. The folder is ready for the game only after
# minisign signs plugin.manifest into plugin.manifest.minisig with the GenOnline
# plugin key.

cmake_minimum_required(VERSION 3.14)

foreach(required PLUGIN_DIR PLUGIN_NAME PLUGIN_VERSION PLUGIN_API_VERSION)
    if (NOT DEFINED ${required} OR "${${required}}" STREQUAL "")
        message(FATAL_ERROR "${required} is required")
    endif()
endforeach()

if (NOT PLUGIN_NAME MATCHES "^[A-Za-z0-9_]+$")
    message(FATAL_ERROR "PLUGIN_NAME '${PLUGIN_NAME}' may only hold letters, digits and underscores")
endif()

if (NOT PLUGIN_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
    message(FATAL_ERROR "PLUGIN_VERSION '${PLUGIN_VERSION}' is not of the form YYYY.MM.PATCH")
endif()

if (NOT PLUGIN_API_VERSION MATCHES "^[0-9]+$")
    message(FATAL_ERROR "PLUGIN_API_VERSION '${PLUGIN_API_VERSION}' is not a number")
endif()

if (NOT IS_DIRECTORY "${PLUGIN_DIR}")
    message(FATAL_ERROR "PLUGIN_DIR '${PLUGIN_DIR}' is not a folder")
endif()

# The plugin library is <name>.dll on Windows, <name>.so on Linux and <name>.dylib on macOS.
set(libraries "")
foreach(suffix .dll .so .dylib)
    if (EXISTS "${PLUGIN_DIR}/${PLUGIN_NAME}${suffix}")
        list(APPEND libraries "${PLUGIN_NAME}${suffix}")
    endif()
endforeach()
list(LENGTH libraries libraryCount)
if (NOT libraryCount EQUAL 1)
    message(FATAL_ERROR "The folder must hold exactly one of ${PLUGIN_NAME}.dll, ${PLUGIN_NAME}.so or ${PLUGIN_NAME}.dylib")
endif()

file(GLOB_RECURSE files LIST_DIRECTORIES false RELATIVE "${PLUGIN_DIR}" "${PLUGIN_DIR}/*")
list(SORT files)

set(entries "")
foreach(path IN LISTS files)
    string(TOLOWER "${path}" lowerPath)
    if (lowerPath STREQUAL "plugin.manifest" OR lowerPath STREQUAL "plugin.manifest.minisig")
        continue()
    endif()

    # The client accepts only letters, digits, dots, underscores and hyphens in a path component, and no component that starts or ends with a dot.
    if (NOT path MATCHES "^[A-Za-z0-9_-]([A-Za-z0-9._-]*[A-Za-z0-9_-])?(/[A-Za-z0-9_-]([A-Za-z0-9._-]*[A-Za-z0-9_-])?)*$")
        message(FATAL_ERROR "The file '${path}' has a name that the client refuses")
    endif()

    file(SHA256 "${PLUGIN_DIR}/${path}" hash)
    file(SIZE "${PLUGIN_DIR}/${path}" size)
    list(APPEND entries "{\"path\":\"${path}\",\"sha256\":\"${hash}\",\"size\":${size}}")
endforeach()

list(JOIN entries "," joinedEntries)
set(manifest "{\"format\":1,\"name\":\"${PLUGIN_NAME}\",\"version\":\"${PLUGIN_VERSION}\",\"api_version\":${PLUGIN_API_VERSION},\"files\":[${joinedEntries}]}")

file(WRITE "${PLUGIN_DIR}/plugin.manifest" "${manifest}")
message(STATUS "Wrote the unsigned ${PLUGIN_DIR}/plugin.manifest")
