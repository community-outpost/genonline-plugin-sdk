# SPDX-License-Identifier: MIT
cmake_minimum_required(VERSION 3.14)
project(genonline_plugin_sdk LANGUAGES NONE)

# The plugin API header for plugins and for the game.
add_library(genonline_plugin_api INTERFACE)
add_library(GenOnline::PluginApi ALIAS genonline_plugin_api)
target_include_directories(genonline_plugin_api INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")

set(GENONLINE_PLUGIN_MANIFEST_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/cmake/GeneratePluginManifest.cmake" CACHE INTERNAL "")

# Adds a target that writes the unsigned plugin.manifest of a staged plugin folder.
# genonline_plugin_manifest(<target> FOLDER <dir> NAME <name> VERSION <YYYY.MM.PATCH> [DEPENDS <targets>...])
function(genonline_plugin_manifest target)
    cmake_parse_arguments(ARG "" "FOLDER;NAME;VERSION" "DEPENDS" ${ARGN})
    foreach(required FOLDER NAME VERSION)
        if (NOT ARG_${required})
            message(FATAL_ERROR "genonline_plugin_manifest: ${required} is required")
        endif()
    endforeach()
    add_custom_target(${target}
        COMMAND "${CMAKE_COMMAND}" -DPLUGIN_DIR=${ARG_FOLDER} -DPLUGIN_NAME=${ARG_NAME} -DPLUGIN_VERSION=${ARG_VERSION} -DPLUGIN_API_VERSION=1 -P "${GENONLINE_PLUGIN_MANIFEST_SCRIPT}"
        DEPENDS ${ARG_DEPENDS}
        VERBATIM)
endfunction()
