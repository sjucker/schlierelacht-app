# CLAUDE.md

Guidance for Claude Code in the Schliere lacht Flutter app. Architecture, the API
contract with the backend, and common commands are documented in the workspace's
`CLAUDE.md` (one level up, when cloned as part of `schlierelacht-workspace`).

## Code formatting

Always format with **Android Studio's formatter settings**, never `dart format`'s
80-column default. For Dart, Android Studio's "Reformat Code" just delegates to
`dart format` with its Dart right margin (160). That width is pinned in
`analysis_options.yaml` (`formatter: page_width: 160`), so these all produce the
same output as the IDE:

- `dart format lib test` (no `--line-length` flag: it reads `page_width`),
- the Dart MCP server's format tool.

After editing any `.dart` file, format it. Before committing, check that the
whole project is clean: `dart format -o none --set-exit-if-changed lib test`
must report `0 changed`.

For non-Dart files (Kotlin/Gradle `*.kts`, XML), use the IDE formatter: the
JetBrains `idea` MCP server's reformat tool when it is connected, or Android
Studio's command-line formatter (`<Android Studio>\bin\format.bat`, which only
runs while Android Studio is closed). If neither is available, match the
surrounding style by hand and say so.

## Flutter agentic development

Set up per <https://docs.flutter.dev/ai/get-started>. `.claude/settings.json`
enables the official **`dart-flutter`** plugin from the `flutter/agent-plugins`
marketplace; Claude Code offers to install it when this folder is trusted. It
provides:

- the **Dart MCP server** (`dart mcp-server`): analysis, formatting, `dart fix`,
  pub / pub.dev search, running tests, and — against a running app — runtime
  errors, widget inspector, hot reload / hot restart;
- the Flutter and Dart **skills** (widget/integration tests, layout fixes, JSON
  serialization, responsive layouts, …).

Manual equivalent: `claude plugin marketplace add flutter/agent-plugins` then
`claude plugin install dart-flutter@dart-flutter`.

Plugins don't load rules, so the Flutter team's rule lives here:

### Proactive hot reload

<!-- From flutter/agent-plugins rules/flutter-hot-reload.md -->

Whenever you edit or modify any `.dart` file under `lib/` in this project:

1. **When to skip**:
    - **Files outside `lib/`**: only trigger hot reload or hot restart for edits
      under `lib/`. Do not trigger when modifying files in other directories (e.g., `test/**`, `integration_test/**`, `benchmark/**`, `test_driver/**`
      or `example/**`).
    - **Comments & documentation**: do not trigger hot reload or hot restart
      when changes only affect comments, docstrings, or whitespace.
2. **Discover & connect**: discover active running application instances using
   the `dtd` MCP tool (or `list_running_apps` / `vm_service`) from the Dart MCP
   server.
3. **Trigger hot reload / hot restart**:
    - Execute the `hot_reload` MCP tool immediately after making changes to UI
      widgets (including `build` methods of stateful widgets) or simple methods.
    - Execute the `hot_restart` MCP tool if fundamental logic, state
      initialization (e.g., `initState`), global/static state, or `main()` was
      modified.

When no app is running, skip this silently. Starting the app needs the
`--dart-define`s from the workspace `CLAUDE.md` (`MAPBOX_ACCESS_TOKEN`,
optionally `API_BASE_URL`).
