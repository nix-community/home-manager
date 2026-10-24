{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.peon-ping;
  jsonFormat = pkgs.formats.json { };

  defaultOgPacksSource = pkgs.fetchFromGitHub {
    owner = "PeonPing";
    repo = "og-packs";
    rev = "v1.1.0";
    hash = "sha256-spao/GTIhH4c5HOmVc0umMvrwOaMRa4s5Pem1AWyUOw=";
  };

  hookCommand = "${cfg.package}/bin/peon";

  hookEntry = event: {
    matcher = "";
    hooks = [
      (
        {
          type = "command";
          command = hookCommand;
          timeout = 10;
        }
        // lib.optionalAttrs (event != "SessionStart") { async = true; }
      )
    ];
  };

  skillNames = [
    "peon-ping-config"
    "peon-ping-toggle"
    "peon-ping-use"
  ];

  packFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".claude/hooks/peon-ping/packs/${name}" {
        source = "${cfg.ogPacksSource}/${name}";
        recursive = true;
      }
    ) cfg.packs
  );

  skillFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".claude/skills/${name}" {
        source = "${cfg.package.src}/skills/${name}";
        recursive = true;
      }
    ) skillNames
  );

  claudeCodeHooks = lib.listToAttrs (
    map (event: lib.nameValuePair event [ (hookEntry event) ]) cfg.claudeCodeHookEvents
  );
in
{
  meta.maintainers = [ lib.maintainers.workflow ];

  options.programs.peon-ping = {
    enable = lib.mkEnableOption "peon-ping, a notification sound player for AI coding agents";

    package = lib.mkPackageOption pkgs "peon-ping" { };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        active_pack = "peon";
        volume = 0.5;
        enabled = true;
        desktop_notifications = true;
        categories = {
          "session.start" = true;
          "task.complete" = true;
          "input.required" = true;
        };
      };
      description = ''
        Declarative peon-ping configuration written to
        {file}`~/.claude/hooks/peon-ping/config.json`.

        When non-empty, the config file is managed by Home Manager as an
        immutable symlink. When left empty (the default), a mutable default
        config is seeded on first activation so that the `peon` CLI and
        Claude Code skills can modify it at runtime.
      '';
    };

    packs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "peon" ];
      example = [
        "peon"
        "peon_de"
        "aoe2"
      ];
      description = ''
        Sound pack names to install from {option}`ogPacksSource`.
        Each name corresponds to a subdirectory in the og-packs repository.
      '';
    };

    ogPacksSource = lib.mkOption {
      type = lib.types.package;
      default = defaultOgPacksSource;
      defaultText = lib.literalExpression ''
        pkgs.fetchFromGitHub {
          owner = "PeonPing";
          repo = "og-packs";
          rev = "v1.1.0";
          hash = "sha256-spao/GTIhH4c5HOmVc0umMvrwOaMRa4s5Pem1AWyUOw=";
        }
      '';
      description = ''
        Source derivation containing sound packs. Pack names in
        {option}`packs` are resolved as subdirectories of this source.
      '';
    };

    enableClaudeCodeIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to automatically configure Claude Code hooks and skills
        for peon-ping integration.

        Requires {option}`programs.claude-code.enable` to be set.
      '';
    };

    claudeCodeHookEvents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "SessionStart"
        "SessionEnd"
        "UserPromptSubmit"
        "Stop"
        "Notification"
        "PermissionRequest"
      ];
      description = ''
        Claude Code hook events to register peon-ping for.
        Each event fires the `peon` command which reads the event
        from stdin and plays the appropriate sound.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.enableClaudeCodeIntegration || config.programs.claude-code.enable;
        message = ''
          `programs.peon-ping.enableClaudeCodeIntegration` requires
          `programs.claude-code.enable` to be set.
        '';
      }
    ];

    home.packages = [ cfg.package ];

    home.file =
      packFiles
      // lib.optionalAttrs cfg.enableClaudeCodeIntegration skillFiles
      // {
        ".claude/hooks/peon-ping/config.json" = lib.mkIf (cfg.settings != { }) {
          source = jsonFormat.generate "peon-ping-config.json" cfg.settings;
        };
      };

    home.activation.seedPeonPingConfig = lib.mkIf (cfg.settings == { }) (
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        peonConfigDir="''${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/peon-ping"
        peonConfigFile="$peonConfigDir/config.json"
        if [ ! -f "$peonConfigFile" ]; then
          run mkdir -p "$peonConfigDir"
          run cp "${cfg.package}/lib/peon-ping/config.json" "$peonConfigFile"
          run chmod u+w "$peonConfigFile"
          verboseEcho "Seeded peon-ping default config at $peonConfigFile"
        fi
      ''
    );

    programs.claude-code.settings = lib.mkIf cfg.enableClaudeCodeIntegration {
      hooks = claudeCodeHooks;
    };
  };
}
