# Generals Online plugin SDK

| Path | Purpose |
|---|---|
| `include/GenOnlinePluginApi.h` | Plugin API (C, `GENONLINE_PLUGIN_API_VERSION` 1) |
| `cmake/GeneratePluginManifest.cmake` | Writes the unsigned `plugin.manifest` |
| `CMakeLists.txt` | `GenOnline::PluginApi` target, `genonline_plugin_manifest()` |

## Usage

```cmake
add_subdirectory(<sdk> genonline-plugin-sdk)
target_link_libraries(my_plugin PRIVATE GenOnline::PluginApi)
genonline_plugin_manifest(my_plugin_manifest FOLDER <staged folder> NAME my_plugin VERSION 2026.11.0 DEPENDS my_plugin)
```

The DLL exports only `GenOnlinePlugin_GetApi`. Tables only grow at the end, and each side reads only the fields inside the other side's `structSize`.

## Plugin folder

The game loads `plugins/<name>/<name>.dll` next to its executable, only for names on its allowlist. On Linux and macOS the library is `<name>.so` or `<name>.dylib`. `<name>` is `[A-Za-z0-9_]`, at most 64 characters.

The game refuses the plugin when the folder holds a file the manifest does not list, or when a listed file differs in size or SHA-256.

## Manifest

```json
{"format":1,"name":"<name>","version":"YYYY.MM.PATCH","api_version":1,"files":[{"path":"<name>.dll","sha256":"<hex>","size":123}]}
```

- Exactly these keys. `name` equals the folder name.
- `files`: every file in the folder except `plugin.manifest` and `plugin.manifest.minisig`, 1 to 256 entries.
- Path components: `[A-Za-z0-9._-]`, no leading or trailing dot.
- Manifest at most 64 KiB, signature at most 4 KiB.

## Signing

```sh
minisign -S -s <secret key file> -m plugins/<name>/plugin.manifest
```

The key must be one of the plugin keys compiled into the game. Release builds load no unsigned plugin.
