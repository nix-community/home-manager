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

  cfg = config.programs.zed-editor;
  jsonFormat = pkgs.formats.json { };
  mutableConfig = config.lib.mutableConfig;

  transformedMcpServers = lib.optionalAttrs (cfg.enableMcpIntegration && config.programs.mcp.enable) (
    lib.mapAttrs (
      name: server:
      # See: https://zed.dev/docs/ai/mcp & https://github.com/zed-industries/zed/discussions/53780
      lib.hm.mcp.transformMcpServer {
        inherit server;
        extraTransforms = [
          lib.hm.mcp.addType
          (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; })
        ];
      }
    ) config.programs.mcp.servers
  );

  settingMcpServers = lib.mapAttrs (_: lib.hm.mcp.addType) (
    lib.attrByPath [ "context_servers" ] { } cfg.userSettings
  );
  mergedMcpServers = transformedMcpServers // settingMcpServers;

  mergedSettings =
    cfg.userSettings
    // (lib.optionalAttrs (builtins.length cfg.extensions > 0) {
      # this part by @cmacrae
      auto_install_extensions = lib.genAttrs cfg.extensions (_: true);
    })
    // (lib.optionalAttrs (mergedMcpServers != { }) {
      context_servers = mergedMcpServers;
    });

  editorEnv = {
    EDITOR = "${cfg.package.meta.mainProgram} --wait";
    VISUAL = "${cfg.package.meta.mainProgram} --wait";
  };
in
{
  meta.maintainers = [
    lib.maintainers.alinnow
    lib.maintainers.zh4ngx
  ];

  options = {
    programs.zed-editor = {
      enable = lib.mkEnableOption "Zed, the high performance, multiplayer code editor from the creators of Atom and Tree-sitter";

      package = lib.mkPackageOption pkgs "zed-editor" { nullable = true; };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression "[ pkgs.nixd ]";
        description = "Extra packages available to Zed.";
      };

      mutableUserSettings = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = ''
          Whether user settings (settings.json) can be updated by zed.
        '';
      };

      mutableUserKeymaps = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = ''
          Whether user keymaps (keymap.json) can be updated by zed.
        '';
      };

      mutableUserTasks = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = ''
          Whether user tasks (tasks.json) can be updated by zed.
        '';
      };

      mutableUserDebug = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = ''
          Whether user debug configurations (debug.json) can be updated by zed.
        '';
      };

      userSettings = mkOption {
        inherit (jsonFormat) type;
        default = { };
        example = {
          features = {
            copilot = false;
          };
          telemetry = {
            metrics = false;
          };
          vim_mode = false;
          ui_font_size = 16;
          buffer_font_size = 16;
        };
        description = ''
          Configuration written to Zed's {file}`settings.json`.
        '';
      };

      userKeymaps = mkOption {
        inherit (jsonFormat) type;
        default = [ ];
        example = literalExpression ''
          [
            {
              context = "Workspace";
              bindings = {
                ctrl-shift-t = "workspace::NewTerminal";
              };
            };
          ]
        '';
        description = ''
          Configuration written to Zed's {file}`keymap.json`.
        '';
      };

      userTasks = mkOption {
        inherit (jsonFormat) type;
        default = [ ];
        example = [
          {
            label = "Format Code";
            command = "nix";
            args = [
              "fmt"
              "$ZED_WORKTREE_ROOT"
            ];
          }
        ];
        description = ''
          Configuration written to Zed's {file}`tasks.json`.

          [List of tasks](https://zed.dev/docs/tasks) that can be run from the
          command palette.
        '';
      };

      userDebug = mkOption {
        inherit (jsonFormat) type;
        default = [ ];
        example = [
          {
            label = "Go (Delve)";
            adapter = "Delve";
            program = "$ZED_FILE";
            request = "launch";
            mode = "debug";
          }
        ];
        description = ''
          Configuration written to Zed's {file}`debug.json`.

          Global debug configurations for Zed's [Debugger](https://zed.dev/docs/debugger).
        '';
      };

      extensions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "swift"
          "nix"
          "xy-zed"
        ];
        description = ''
          A list of the extensions Zed should install on startup.
          Use the name of a repository in the [extension list](https://github.com/zed-industries/extensions/tree/main/extensions).
        '';
      };

      installRemoteServer = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether to symlink the Zed's remote server binary to the expected
          location. This allows remotely connecting to this system from a
          distant Zed client.

          For more information, consult the
          ["Remote Server" section](https://wiki.nixos.org/wiki/Zed#Remote_Server)
          in the wiki.
        '';
      };

      enableMcpIntegration = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to integrate the MCP server config from
          {option}`programs.mcp.servers` into
          {option}`programs.zed-editor.userSettings.context_servers`.

          Note: Settings defined in {option}`programs.zed-editor.userSettings.context_servers`
          will take precedence over the generated MCP configuration.
        '';
      };

      themes = mkOption {
        description = ''
          Each theme is written to
          {file}`$XDG_CONFIG_HOME/zed/themes/theme-name.json`
          where the name of each attribute is the theme-name

          See <https://zed.dev/docs/extensions/themes> for the structure of a
          Zed theme
        '';
        type = types.attrsOf (
          types.oneOf [
            jsonFormat.type
            types.path
            types.lines
          ]
        );
        default = { };
      };

      defaultEditor = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to set {command}`zeditor -w` as the default editor using the
          {env}`EDITOR` and {env}`VISUAL` environment variables.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.extraPackages != [ ] -> cfg.package != null;
        message = "{option}programs.zed-editor.extraPackages requires non null {option}programs.zed-editor.package";
      }
      {
        assertion = cfg.defaultEditor -> cfg.package != null;
        message = "{option}programs.zed-editor.defaultEditor requires non null {option}programs.zed-editor.package";
      }
    ];

    home.packages = mkIf (cfg.package != null) (
      if cfg.extraPackages != [ ] then
        [
          (pkgs.symlinkJoin {
            name = "${lib.getName cfg.package}-wrapped-${lib.getVersion cfg.package}";
            paths = [ cfg.package ];
            preferLocalBuild = true;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/${cfg.package.meta.mainProgram or "zeditor"} \
                --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
            '';
          })
        ]
      else
        [ cfg.package ]
    );

    home.file = mkIf (cfg.installRemoteServer && (cfg.package ? remote_server)) (
      let
        inherit (cfg.package) remote_server;
        binaryName = cfg.package.remoteServerExecutableName;
      in
      {
        ".zed_server/${binaryName}".source = lib.getExe' remote_server binaryName;
      }
    );

    home.mutableConfig = mkMerge [
      (mkIf (cfg.mutableUserSettings && mergedSettings != { }) {
        "${config.xdg.configHome}/zed/settings.json" = {
          data = mergedSettings;
          onInvalid = "initialize";
        };
      })
      (mkIf (cfg.mutableUserKeymaps && cfg.userKeymaps != [ ]) {
        "${config.xdg.configHome}/zed/keymap.json" = {
          data = mutableConfig.mergeBy "context" cfg.userKeymaps;
          onInvalid = "initialize";
        };
      })
      (mkIf (cfg.mutableUserTasks && cfg.userTasks != [ ]) {
        "${config.xdg.configHome}/zed/tasks.json" = {
          data = mutableConfig.mergeBy "label" cfg.userTasks;
          onInvalid = "initialize";
        };
      })
      (mkIf (cfg.mutableUserDebug && cfg.userDebug != [ ]) {
        "${config.xdg.configHome}/zed/debug.json" = {
          data = mutableConfig.mergeBy "label" cfg.userDebug;
          onInvalid = "initialize";
        };
      })
    ];

    xdg.configFile = mkMerge [
      (lib.mapAttrs' (
        n: v:
        lib.nameValuePair "zed/themes/${n}.json" {
          source =
            if lib.isString v then
              pkgs.writeText "zed-theme-${n}" v
            else if builtins.isPath v || lib.isStorePath v then
              v
            else
              jsonFormat.generate "zed-theme-${n}" v;
        }
      ) cfg.themes)
      (mkIf (!cfg.mutableUserSettings && mergedSettings != { }) {
        "zed/settings.json".source = jsonFormat.generate "zed-user-settings" mergedSettings;
      })
      (mkIf (!cfg.mutableUserKeymaps && cfg.userKeymaps != [ ]) {
        "zed/keymap.json".source = jsonFormat.generate "zed-user-keymaps" cfg.userKeymaps;
      })
      (mkIf (!cfg.mutableUserTasks && cfg.userTasks != [ ]) {
        "zed/tasks.json".source = jsonFormat.generate "zed-user-tasks" cfg.userTasks;
      })
      (mkIf (!cfg.mutableUserDebug && cfg.userDebug != [ ]) {
        "zed/debug.json".source = jsonFormat.generate "zed-user-debug" cfg.userDebug;
      })
    ];

    home.sessionVariables = mkIf cfg.defaultEditor editorEnv;
  };
}
