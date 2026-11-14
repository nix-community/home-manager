{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.programs.t3code;
  jsonFormat = pkgs.formats.json { };
  json5 = pkgs.python3Packages.toPythonApplication pkgs.python3Packages.json5;

  immutableFiles = {
    settings = !cfg.mutableUserSettings && cfg.userSettings != { };
    keybindings = !cfg.mutableKeybindings && cfg.keybindings != [ ];
    client-settings = !cfg.mutableClientSettings && cfg.clientSettings != { };
  };

  immutableConfigCleanup = lib.concatMapStrings (
    name:
    lib.hm.generators.mkImpureConfigCleanup {
      file = config.home.file.".t3/userdata/${name}.json";
    }
  ) (lib.attrNames (lib.filterAttrs (_: lib.id) immutableFiles));

  userDataDir = "${config.home.homeDirectory}/.t3/userdata";

  themesDir = "${userDataDir}/themes";

  themeSources = lib.mapAttrs (
    id: value:
    if builtins.isAttrs value && !lib.isDerivation value then
      jsonFormat.generate "t3code-theme-${id}" value
    else
      value
  ) cfg.themes;

  # t3code clients apply a default theme once per generation token, so the
  # token has to change when the selected theme's content changes. For an
  # attribute set the generated store path already depends on the content.
  themeToken = id: builtins.hashString "sha256" "${id}:${toString themeSources.${id}}";

  # Nix's regular expressions are POSIX ERE and have no negative lookahead, so
  # the reserved ids are checked separately. These mirror upstream's
  # RESERVED_THEME_IDS: appearance keywords, built-in themes, and legacy aliases.
  reservedThemeIds = [
    "system"
    "light"
    "dark"
    "t3-chat"
    "grove"
    "ocean"
    "ember"
    "iris"
    "t3-chat-dark"
    "t3-grove"
    "t3-ocean"
    "t3-ember"
    "t3-iris"
    "t3-code"
  ];

  validThemeId =
    id: builtins.match "^[a-z0-9][a-z0-9-]{0,47}$" id != null && !lib.elem id reservedThemeIds;

  cmp = lib.getExe' pkgs.diffutils "cmp";
  cp = lib.getExe' pkgs.coreutils "cp";
  chmod = lib.getExe' pkgs.coreutils "chmod";
  mkdir = lib.getExe' pkgs.coreutils "mkdir";
  mktemp = lib.getExe' pkgs.coreutils "mktemp";
  mv = lib.getExe' pkgs.coreutils "mv";

  # t3code's loader opens theme files with O_NOFOLLOW, so a home.file symlink
  # into the Nix store would be ignored. Materialize a regular file instead,
  # writing to a temporary file in the same directory and renaming over the
  # target so an existing symlink is replaced rather than followed.
  materializeTheme =
    id:
    let
      source = toString themeSources.${id};
      target = "${themesDir}/${id}.json";
    in
    ''
      theme_source=${lib.escapeShellArg source}
      theme_target=${lib.escapeShellArg target}
      if [ -L "$theme_target" ] || ! ${cmp} -s "$theme_source" "$theme_target"; then
        theme_tmp=$(${mktemp} ${lib.escapeShellArg "${themesDir}/.${id}.json.XXXXXXXX"})
        ${cp} "$theme_source" "$theme_tmp"
        ${chmod} 0644 "$theme_tmp"
        ${mv} -fT "$theme_tmp" "$theme_target"
      fi
    '';

  serverCfg = cfg.server;

  # t3code's headless server binary. pkgs.t3code's mainProgram is the Electron
  # desktop app (t3code-desktop); the server run as a service is `t3`.
  # The package wraps `t3` with the coding-agent and VCS CLIs it drives.
  serverExe = lib.getExe' cfg.package "t3";

  serverArgs = [
    "serve"
  ]
  ++ serverCfg.extraArgs;
in
{
  meta.maintainers = [
    lib.maintainers.iamanaws
    lib.maintainers.jonocodes
  ];

  options.programs.t3code = {
    enable = lib.mkEnableOption "T3 Code, a minimal web GUI for coding agents";

    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.t3code or null;
      defaultText = literalExpression "pkgs.t3code";
      example = literalExpression ''
        pkgs.t3code.override {
          enableClaude = true;
          enableOpencode = true;
        }
      '';
      description = ''
        The t3code package to install.

        The package puts {command}`git`, {command}`gh` and {command}`codex` on
        t3code's {env}`PATH` by default. Override it to enable other CLIs,
        such as Claude Code or OpenCode, for both the desktop app and the
        server.
      '';
    };

    mutableUserSettings = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether user settings ({file}`settings.json`) can be updated by t3code.
      '';
    };

    mutableKeybindings = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether user keybindings ({file}`keybindings.json`) can be updated by t3code.
      '';
    };

    mutableClientSettings = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether client settings ({file}`client-settings.json`) can be updated by t3code.
      '';
    };

    userSettings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        enableProviderUpdateChecks = false;
        providerInstances = {
          codex = {
            driver = "codex";
            enabled = true;
            config = {
              enabled = true;
              binaryPath = "codex";
              homePath = "";
              shadowHomePath = "";
              customModels = [ ];
            };
          };
        };
      };
      description = ''
        Configuration written to t3code's {file}`settings.json`.
      '';
    };

    keybindings = mkOption {
      inherit (jsonFormat) type;
      default = [ ];
      example = [
        {
          key = "mod+j";
          command = "terminal.toggle";
        }
        {
          key = "mod+d";
          command = "terminal.split";
          when = "terminalFocus";
        }
        {
          key = "mod+d";
          command = "diff.toggle";
          when = "!terminalFocus";
        }
      ];
      description = ''
        Configuration written to t3code's {file}`keybindings.json`.
      '';
    };

    clientSettings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        favorites = [
          {
            provider = "codex";
            model = "gpt-5.5";
          }
        ];
        sidebarProjectGroupingMode = "repository";
        timestampFormat = "locale";
      };
      description = ''
        Configuration written to t3code's {file}`client-settings.json`.
      '';
    };

    themes = mkOption {
      type = types.attrsOf (types.either types.path jsonFormat.type);
      default = { };
      example = {
        nightfall = {
          name = "Nightfall";
          appearance = "dark";
          canvas = "#1a1b26";
          accent = "#7aa2f7";
          colors.terminalSelection = "#292e42";
        };
      };
      description = ''
        Environment themes published to {file}`~/.t3/userdata/themes`.

        The attribute name is the theme id. It must be 1 to 48 characters of
        lowercase letters, digits, and hyphens, and must not be a reserved id
        (`system`, `light`, `dark`, a built-in theme such as `t3-chat` or
        `grove`, or a legacy alias such as `t3-grove`). The value is either a
        path to a JSON theme file or an attribute set that Home Manager
        serializes to JSON. The accepted fields are described in the
        [environment theme format](https://github.com/pingdotgg/t3code/blob/main/packages/contracts/src/server.ts).

        t3code's theme loader opens each file with `O_NOFOLLOW`, so a
        {option}`home.file` symlink into the Nix store would be ignored. Home
        Manager therefore writes each theme as a regular file, replacing an
        existing file or symlink. Other files in the themes directory are
        left alone.

        t3code ignores theme files larger than 32 KiB and stops reading after
        32 theme files.
      '';
    };

    defaultTheme = mkOption {
      type = types.nullOr (types.strMatching "^[a-z0-9][a-z0-9-]{0,47}$");
      default = null;
      example = "nightfall";
      description = ''
        Theme id to make the default for web and desktop clients.

        The id must name an entry in {option}`programs.t3code.themes`. Home
        Manager writes it to {file}`settings.json` as `defaultTheme` and sets
        `defaultThemeSetAt` from the theme's content, so connected clients
        reapply the theme when its content changes. Set
        {option}`programs.t3code.userSettings.defaultThemeSetAt` to override
        the generated token.
      '';
    };

    server = {
      enable = lib.mkEnableOption "the t3code headless server as a user service";

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "--host"
          "0.0.0.0"
          "--port"
          "3773"
        ];
        description = ''
          Extra arguments passed to {command}`t3 serve`, for example
          `--host` and `--port`. Run {command}`t3 serve --help` for the
          full list.
        '';
      };

      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/t3code";
        description = ''
          Path to an environment file (see {manpage}`systemd.exec(5)`) loaded by
          the service. The recommended way to pass secrets without exposing them
          in the Nix store.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    programs.t3code.userSettings = mkIf (cfg.defaultTheme != null) (
      lib.mkDefault {
        inherit (cfg) defaultTheme;
        defaultThemeSetAt = themeToken cfg.defaultTheme;
      }
    );

    home.activation = mkMerge [
      (mkIf (immutableConfigCleanup != "") {
        t3codeImmutableConfig =
          lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
            immutableConfigCleanup;
      })
      (mkIf (cfg.mutableUserSettings && cfg.userSettings != { }) {
        t3codeSettingsActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.hm.generators.mkImpureConfigMerger {
            inherit pkgs;
            format = "json";
            empty = "{}";
            jqOperation = "$dynamic * $static";
            path = "${userDataDir}/settings.json";
            mode = "600";
            staticSettings = jsonFormat.generate "t3code-user-settings" cfg.userSettings;
            reader = "${lib.getExe json5} --as-json";
          }
        );
      })
      (mkIf (cfg.mutableKeybindings && cfg.keybindings != [ ]) {
        t3codeKeybindingsActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.hm.generators.mkImpureConfigMerger {
            inherit pkgs;
            format = "json";
            empty = "[]";
            jqOperation = "$dynamic + $static | group_by([.key, .when]) | map(reduce .[] as $item ({}; . * $item))";
            path = "${userDataDir}/keybindings.json";
            staticSettings = jsonFormat.generate "t3code-user-keybindings" cfg.keybindings;
            reader = "${lib.getExe json5} --as-json";
          }
        );
      })
      (mkIf (cfg.mutableClientSettings && cfg.clientSettings != { }) {
        t3codeClientSettingsActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.hm.generators.mkImpureConfigMerger {
            inherit pkgs;
            format = "json";
            empty = "{}";
            jqOperation = "$dynamic * $static";
            path = "${userDataDir}/client-settings.json";
            staticSettings = jsonFormat.generate "t3code-client-settings" cfg.clientSettings;
            reader = "${lib.getExe json5} --as-json";
          }
        );
      })
      (mkIf (cfg.themes != { }) {
        t3codeThemes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          theme_dir=${lib.escapeShellArg themesDir}
          ${mkdir} -p "$theme_dir"
          ${lib.concatMapStringsSep "\n" materializeTheme (lib.attrNames cfg.themes)}
        '';
      })
    ];

    home.file = mkMerge [
      (mkIf (!cfg.mutableUserSettings && cfg.userSettings != { }) {
        ".t3/userdata/settings.json".source = jsonFormat.generate "t3code-user-settings" cfg.userSettings;
      })
      (mkIf (!cfg.mutableKeybindings && cfg.keybindings != [ ]) {
        ".t3/userdata/keybindings.json".source =
          jsonFormat.generate "t3code-user-keybindings" cfg.keybindings;
      })
      (mkIf (!cfg.mutableClientSettings && cfg.clientSettings != { }) {
        ".t3/userdata/client-settings.json".source =
          jsonFormat.generate "t3code-client-settings" cfg.clientSettings;
      })
    ];

    assertions = [
      {
        assertion = !serverCfg.enable || cfg.package != null;
        message = "programs.t3code.server.enable requires programs.t3code.package to be set (it is null).";
      }
      {
        assertion = builtins.all validThemeId (lib.attrNames cfg.themes);
        message = "programs.t3code.themes keys must be valid T3 environment theme ids: 1 to 48 characters of lowercase letters, digits, and hyphens, and not a reserved id (system, light, dark, a built-in theme, or a legacy alias).";
      }
      {
        assertion = cfg.defaultTheme == null || lib.hasAttr cfg.defaultTheme cfg.themes;
        message = "programs.t3code.defaultTheme \"${cfg.defaultTheme}\" does not match any programs.t3code.themes entry.";
      }
    ];

    systemd.user.services = mkIf serverCfg.enable {
      t3code = {
        Unit = {
          Description = "t3code headless server";
          Documentation = "https://t3.codes";
          After = [ "network.target" ];
        };

        Service = {
          ExecStart = "${serverExe} ${lib.escapeShellArgs serverArgs}";
          Restart = "on-failure";
          RestartSec = 5;
        }
        // lib.optionalAttrs (serverCfg.environmentFile != null) {
          EnvironmentFile = serverCfg.environmentFile;
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };

    launchd.agents = mkIf serverCfg.enable {
      t3code = {
        enable = true;
        config = {
          ProgramArguments =
            let
              launchdWrapper = pkgs.writeShellScriptBin "t3code-launchd-wrapper" ''
                set -a
                source ${lib.escapeShellArg (toString serverCfg.environmentFile)} || exit 1
                set +a
                exec ${serverExe} ${lib.escapeShellArgs serverArgs}
              '';
            in
            if serverCfg.environmentFile == null then
              [ serverExe ] ++ serverArgs
            else
              [ (lib.getExe launchdWrapper) ];
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
          ProcessType = "Background";
          RunAtLoad = true;
        };
      };
    };
  };
}
