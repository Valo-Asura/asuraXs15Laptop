{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  memoryRoot = "${homeDir}/.config/ai-unified-memory";
  memoryDb = "${memoryRoot}/memory/history.db";

  agentInstructions = ''
    # Global Agent Instructions

    ## Scope
    This memory root is system-scoped. Store durable facts about the
    `/etc/nixos` laptop configuration, deployment, validation, and known
    hardware gotchas. Do not store personal biography, preferences, role, or
    language-profile facts here.

    ## Coding Rules
    - Prefer full implementations over fragments.
    - Python: type hints, small functions, clear modules.
    - TypeScript: explicit interfaces/types.
    - Prefer composition over inheritance.
    - Keep functions focused and under ~40 lines where practical.
    - Add security notes for SQLi, XSS, IDOR, auth, and secret risks.

    ## System Rules
    - NixOS/Arch Linux workflows should be reproducible.
    - Prefer declarative config when possible.
    - Do not suggest destructive shell commands without checks.
    - For editor/agent config, prefer pinned packages and env vars.

    ## Output Style
    - Blunt, dense, precise.
    - Use tables and code blocks.
    - No filler.

    ## Unified AI Memory
    All local AI agents should use the same memory root:

    ```text
    ${memoryRoot}
    ```

    Primary stores:
    - Filesystem memory: `${memoryRoot}`
    - SQLite memory: `${memoryDb}`
    - Facts: `${memoryRoot}/memory/facts.json`
    - Lessons: `${memoryRoot}/memory/lessons.json`

    Connected clients:
    - Codex: `~/.codex/AGENTS.md`, `~/.codex/config.toml`
    - Cursor: `~/.cursor/rules/ai-unified-memory.mdc`, `~/.cursor/mcp.json`
    - Kiro: `~/.kiro/steering/AGENTS.md`, `~/.kiro/settings/mcp.json`
    - Antigravity: `~/.antigravity/rules/ai-unified-memory.md`, `~/.config/Antigravity/User/AGENTS.md`
    - Warp: `~/.warp/ai-unified-memory.md`

    At session start, read the shared facts/lessons and query SQLite memories when available.
    On task completion, add durable facts, lessons, and gotchas to the shared store.

    ## Desktop Shell Context
    - Active stable shell: `/etc/nixos/asura-xs15/noctaliaShell` (Noctalia).
    - Hyprland lock, clipboard, wallpaper, launcher, and session actions should route through Noctalia IPC.
    - Screenshots should use `asura-screenshot` instead of shell IPC so feature proof captures work while panels/launchers are open or optional shells are active.
    - Keep NVIDIA persistenced enabled so monitor/NVML tools can see the dGPU while idle.
    - Removed shell experiments should not be reintroduced without an explicit user request.
  '';

  factsSeed = {
    asura_xs15_nixos = {
      host = "asura-xs15";
      repo_path = "/etc/nixos";
      tree_root = "/etc/nixos/asura-xs15";
      system_module_layout = "flat files: /etc/nixos/asura-xs15/system/<module>.nix";
    };
  };

  mcpServers = {
    "ai-memory-files" = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem"
        memoryRoot
      ];
    };
    "ai-memory-sqlite" = {
      command = "uvx";
      args = [
        "mcp-server-sqlite"
        "--db-path"
        memoryDb
      ];
    };
  };

  activeMcpServers = {
    "ai-memory-files" = mcpServers."ai-memory-files";
  };

  lazyMcpServers = {
    "ai-memory-sqlite" = mcpServers."ai-memory-sqlite";
  };

  vscodeServers = lib.mapAttrs (
    _: server:
    {
      type = "stdio";
      sandboxEnabled = true;
    }
    // server
  ) activeMcpServers;

  vscodeLazyServers = lib.mapAttrs (
    _: server:
    {
      type = "stdio";
      sandboxEnabled = true;
    }
    // server
  ) lazyMcpServers;

  mcpBase = {
    servers = activeMcpServers;
  };

  mcpSqliteOptIn = {
    servers = activeMcpServers // lazyMcpServers;
  };

  staleMcpServerKeys = [
    "aiMemoryFiles"
    "aiMemorySqlite"
    "ai-memory-sqlite"
    "asura-ai-memory"
    "asura-ai-memory-files"
    "asura-qdrant-memory"
    "asura-memorix"
  ];

  manifest = {
    version = 1;
    root = memoryRoot;
    sqlite = memoryDb;
    agents = {
      codex = {
        instructions = "${homeDir}/.codex/AGENTS.md";
        mcp = "${homeDir}/.codex/config.toml";
      };
      cursor = {
        instructions = "${homeDir}/.cursor/rules/ai-unified-memory.mdc";
        mcp = "${homeDir}/.cursor/mcp.json";
      };
      kiro = {
        instructions = "${homeDir}/.kiro/steering/AGENTS.md";
        mcp = "${homeDir}/.kiro/settings/mcp.json";
      };
      antigravity = {
        instructions = "${homeDir}/.antigravity/rules/ai-unified-memory.md";
        mcp = "${homeDir}/.config/Antigravity/User/mcp.json";
      };
      warp = {
        instructions = "${homeDir}/.warp/ai-unified-memory.md";
        mcp = null;
      };
    };
  };

  aiMemoryMcpStatus = pkgs.writeShellScriptBin "ai-memory-mcp-status" ''
    ps -eo pid,rss,pcpu,comm,args --sort=-rss \
      | ${pkgs.ripgrep}/bin/rg -i 'mcp-server|modelcontextprotocol|ai-memory|uvx' || true
  '';

  aiMemoryMcpStop = pkgs.writeShellScriptBin "ai-memory-mcp-stop" ''
    set -euo pipefail

    ${pkgs.procps}/bin/pkill -f "mcp-server-sqlite --db-path ${memoryDb}" >/dev/null 2>&1 || true
    ${pkgs.procps}/bin/pkill -f "@modelcontextprotocol/server-filesystem ${memoryRoot}" >/dev/null 2>&1 || true
    ${pkgs.procps}/bin/pkill -f "mcp-server-filesystem ${memoryRoot}" >/dev/null 2>&1 || true
  '';

  asuraAiMemory = pkgs.writeShellScriptBin "asura-ai-memory" ''
    set -euo pipefail

    case "''${1:-status}" in
      status)
        echo "root: ${memoryRoot}"
        echo "db:   ${memoryDb}"
        echo
        exec ai-memory-mcp-status
        ;;
      stop-mcp)
        exec ai-memory-mcp-stop
        ;;
      paths)
        echo "${memoryRoot}"
        echo "${memoryDb}"
        echo "${memoryRoot}/mcp/config.base.json"
        echo "${memoryRoot}/mcp/config.sqlite-opt-in.json"
        ;;
      *)
        echo "usage: asura-ai-memory [status|stop-mcp|paths]" >&2
        exit 2
        ;;
    esac
  '';

  syncScript = pkgs.writeText "sync-ai-unified-memory.py" ''
    import json
    import os
    import shutil
    import sqlite3
    from datetime import datetime
    from pathlib import Path

    HOME = Path(os.environ["HOME"])
    ROOT = Path(${builtins.toJSON memoryRoot})
    DB = Path(${builtins.toJSON memoryDb})
    AGENT_INSTRUCTIONS = ${builtins.toJSON agentInstructions}
    FACTS_SEED = json.loads(${builtins.toJSON (builtins.toJSON factsSeed)})
    MCP_BASE = json.loads(${builtins.toJSON (builtins.toJSON mcpBase)})
    MCP_SQLITE_OPT_IN = json.loads(${builtins.toJSON (builtins.toJSON mcpSqliteOptIn)})
    CURSOR_SERVERS = json.loads(${builtins.toJSON (builtins.toJSON activeMcpServers)})
    VSCODE_SERVERS = json.loads(${builtins.toJSON (builtins.toJSON vscodeServers)})
    VSCODE_LAZY_SERVERS = json.loads(${builtins.toJSON (builtins.toJSON vscodeLazyServers)})
    MANIFEST = json.loads(${builtins.toJSON (builtins.toJSON manifest)})
    STALE_MCP_SERVER_KEYS = json.loads(${builtins.toJSON (builtins.toJSON staleMcpServerKeys)})

    def mkdir(path):
        path.mkdir(parents=True, exist_ok=True)

    def backup(path):
        if not path.exists():
            return
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        shutil.copyfile(path, path.with_suffix(path.suffix + ".bak-" + stamp))

    def load_json(path):
        if not path.exists():
            return {}
        try:
            text = path.read_text(encoding="utf-8").strip()
            return json.loads(text) if text else {}
        except json.JSONDecodeError:
            backup(path)
            return {}

    def write_json(path, data):
        mkdir(path.parent)
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    def write_text(path, text):
        mkdir(path.parent)
        path.write_text(text, encoding="utf-8")

    def merge_json_key(path, key, servers, remove=None):
        data = load_json(path)
        current = data.get(key)
        if not isinstance(current, dict):
            current = {}
        for name in remove or []:
            current.pop(name, None)
        current.update(servers)
        data[key] = current
        write_json(path, data)

    def merge_codex_config(path):
        marker_start = "# BEGIN ai-unified-memory"
        marker_end = "# END ai-unified-memory"
        existing = path.read_text(encoding="utf-8") if path.exists() else ""

        if marker_start in existing and marker_end in existing:
            head = existing.split(marker_start, 1)[0].rstrip()
            tail = existing.split(marker_end, 1)[1].lstrip()
            existing = (head + "\n\n" + tail).strip()

        block = f"""
    {marker_start}

    [mcp_servers.ai-memory-files]
    command = "npx"
    args = ["-y", "@modelcontextprotocol/server-filesystem", "{ROOT}"]
    enabled = true
    default_tools_approval_mode = "prompt"

    # SQLite MCP is intentionally opt-in to avoid long-lived Python/uvx MCP
    # processes in every editor session. Use {ROOT}/mcp/config.sqlite-opt-in.json
    # when an agent needs the heavier SQLite server.

    [plugins."github@openai-curated"]
    enabled = true

    [plugins."notion@openai-curated"]
    enabled = true

    {marker_end}
    """.strip()
        final = (existing + "\n\n" + block + "\n").lstrip()
        mkdir(path.parent)
        path.write_text(final, encoding="utf-8")

    def repair_codex_state():
        codex_dir = HOME / ".codex"
        mkdir(codex_dir / "plugins" / "cache")
        mkdir(codex_dir / "cache")
        mkdir(codex_dir / "tmp")

        for path in [
            codex_dir,
            codex_dir / "plugins",
            codex_dir / "plugins" / "cache",
            codex_dir / "cache",
            codex_dir / "tmp",
        ]:
            try:
                path.chmod(0o700)
            except OSError:
                pass

        for root in [codex_dir / "plugins", codex_dir / "cache"]:
            if not root.exists():
                continue
            for current, dirs, files in os.walk(root):
                for name in dirs + files:
                    item = Path(current) / name
                    if item.is_symlink() and not item.exists():
                        try:
                            item.unlink()
                        except OSError:
                            pass

        for path in [codex_dir / "auth.json", codex_dir / "config.toml"]:
            if path.exists() and not path.is_symlink():
                try:
                    path.chmod(0o600)
                except OSError:
                    pass

    def ensure_sqlite():
        mkdir(DB.parent)
        conn = sqlite3.connect(DB)
        try:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS memories (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    kind TEXT NOT NULL,
                    source TEXT NOT NULL,
                    content TEXT NOT NULL,
                    tags TEXT,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_memories_kind ON memories(kind)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_memories_tags ON memories(tags)")
            content = "Unified memory is shared by Codex, Cursor, Kiro, Antigravity, and Warp from ~/.config/ai-unified-memory."
            exists = conn.execute(
                "SELECT 1 FROM memories WHERE kind = ? AND source = ? AND content = ? LIMIT 1",
                ("fact", "nixos-home-manager", content),
            ).fetchone()
            if not exists:
                conn.execute(
                    "INSERT INTO memories (kind, source, content, tags) VALUES (?, ?, ?, ?)",
                    ("fact", "nixos-home-manager", content, "ai-memory,agents,nixos"),
                )
            conn.commit()
        finally:
            conn.close()

    def ensure_base_memory():
        mkdir(ROOT / "memory")
        mkdir(ROOT / "mcp")
        mkdir(ROOT / "rules")
        mkdir(ROOT / "projects")
        write_text(ROOT / "AGENTS.md", AGENT_INSTRUCTIONS)
        write_json(ROOT / "mcp" / "config.base.json", MCP_BASE)
        write_json(ROOT / "mcp" / "config.sqlite-opt-in.json", MCP_SQLITE_OPT_IN)
        write_json(ROOT / "mcp" / "vscode.sqlite-opt-in.json", {"servers": {**VSCODE_SERVERS, **VSCODE_LAZY_SERVERS}})
        write_json(ROOT / "agents.json", MANIFEST)

        facts_path = ROOT / "memory" / "facts.json"
        facts = load_json(facts_path)
        if not facts:
            facts = FACTS_SEED
        facts.pop("user", None)
        facts["ai_unified_memory"] = {
            "root": str(ROOT),
            "sqlite": str(DB),
            "agents": sorted(MANIFEST["agents"].keys()),
            "scope": "system-only",
        }
        facts["desktop_shell"] = {
            "active": "noctalia",
            "noctalia_path": "/etc/nixos/asura-xs15/noctaliaShell",
            "current_focus": [
                "Noctalia IPC keybinds",
                "Noctalia lockscreen image",
                "NVIDIA dGPU monitor visibility",
                "low-stutter Hyprland behavior",
                "XDM browser download integration",
            ],
        }
        write_json(facts_path, facts)

        lessons_path = ROOT / "memory" / "lessons.json"
        lessons = load_json(lessons_path)
        if not isinstance(lessons, list):
            lessons = []
        lesson = {
            "topic": "AI Unified Memory",
            "lesson": "Keep facts, lessons, and history shared across Codex, Cursor, Kiro, Antigravity, and Warp.",
            "solution": "Use ~/.config/ai-unified-memory and the configured MCP filesystem/SQLite servers.",
        }
        if lesson not in lessons:
            lessons.append(lesson)
        shell_lesson = {
            "topic": "Desktop Shell Workflow",
            "lesson": "Keep Noctalia as the single active desktop shell unless the user explicitly asks for another shell.",
            "solution": "Route lock, clipboard, wallpaper, launcher, and session actions through Noctalia IPC, but keep screenshots on the shell-independent asura-screenshot helper so proof captures include open panels and optional shells.",
        }
        if shell_lesson not in lessons:
            lessons.append(shell_lesson)
        write_json(lessons_path, lessons)

    def record_shell_update():
        mkdir(DB.parent)
        conn = sqlite3.connect(DB)
        try:
            content = "Desktop shell update: Noctalia is the selected active shell; lock, clipboard, wallpaper, launcher, and session keybinds should route through Noctalia IPC. Screenshots use asura-screenshot so captures work while panels or optional shells are open."
            exists = conn.execute(
                "SELECT 1 FROM memories WHERE kind = ? AND source = ? AND content = ? LIMIT 1",
                ("fact", "nixos-home-manager", content),
            ).fetchone()
            if not exists:
                conn.execute(
                    "INSERT INTO memories (kind, source, content, tags) VALUES (?, ?, ?, ?)",
                    ("fact", "nixos-home-manager", content, "desktop-shell,noctalia,nixos"),
                )
            conn.commit()
        finally:
            conn.close()

    def sync_agents():
        repair_codex_state()
        write_text(HOME / ".codex" / "AGENTS.md", AGENT_INSTRUCTIONS)
        merge_codex_config(HOME / ".codex" / "config.toml")
        repair_codex_state()

        write_text(HOME / ".cursor" / "rules" / "ai-unified-memory.mdc", AGENT_INSTRUCTIONS)
        merge_json_key(HOME / ".cursor" / "mcp.json", "mcpServers", CURSOR_SERVERS, STALE_MCP_SERVER_KEYS)

        write_text(HOME / ".kiro" / "steering" / "AGENTS.md", AGENT_INSTRUCTIONS)
        merge_json_key(HOME / ".kiro" / "settings" / "mcp.json", "mcpServers", CURSOR_SERVERS, STALE_MCP_SERVER_KEYS)

        write_text(HOME / ".antigravity" / "rules" / "ai-unified-memory.md", AGENT_INSTRUCTIONS)
        merge_json_key(HOME / ".antigravity" / "mcp.json", "mcpServers", CURSOR_SERVERS, STALE_MCP_SERVER_KEYS)
        write_text(HOME / ".config" / "Antigravity" / "User" / "AGENTS.md", AGENT_INSTRUCTIONS)
        merge_json_key(HOME / ".config" / "Antigravity" / "User" / "mcp.json", "servers", VSCODE_SERVERS, STALE_MCP_SERVER_KEYS)

        merge_json_key(HOME / ".config" / "Code" / "User" / "mcp.json", "servers", VSCODE_SERVERS, STALE_MCP_SERVER_KEYS)
        merge_json_key(HOME / ".config" / "Cursor" / "User" / "mcp.json", "servers", VSCODE_SERVERS, STALE_MCP_SERVER_KEYS)
        merge_json_key(HOME / ".config" / "Kiro" / "User" / "mcp.json", "servers", VSCODE_SERVERS, STALE_MCP_SERVER_KEYS)

        write_text(HOME / ".warp" / "ai-unified-memory.md", AGENT_INSTRUCTIONS)
        write_json(HOME / ".warp-terminal" / "ai-unified-memory.json", MANIFEST)

    ensure_base_memory()
    ensure_sqlite()
    record_shell_update()
    sync_agents()
  '';
in
{
  home.packages = with pkgs; [
    asuraAiMemory
    aiMemoryMcpStatus
    aiMemoryMcpStop
    nodejs
    sqlite
    uv
  ];

  home.sessionVariables = {
    AI_UNIFIED_MEMORY_DIR = memoryRoot;
    AI_UNIFIED_MEMORY_DB = memoryDb;
    AI_MEMORY_PROJECT = "/etc/nixos";
  };

  home.activation.syncAiUnifiedMemory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${syncScript}
  '';

  systemd.user.services.ai-unified-memory-sync = {
    Unit.Description = "Sync unified AI memory context";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${syncScript}";
    };
  };

  systemd.user.timers.ai-unified-memory-sync = {
    Unit.Description = "Daily unified AI memory review/update";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "ai-unified-memory-sync.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
