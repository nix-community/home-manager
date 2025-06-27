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
  json5 = pkgs.python3Packages.toPythonApplication pkgs.python3Packages.json5;
  impureConfigMerger = empty: jqOperation: path: staticSettings: ''
    mkdir -p $(dirname ${lib.escapeShellArg path})
    if [ ! -e ${lib.escapeShellArg path} ]; then
      # No file? Create it
      echo ${lib.escapeShellArg empty} > ${lib.escapeShellArg path}
    fi
    dynamic="$(${lib.getExe json5} --as-json ${lib.escapeShellArg path})"
    static="$(cat ${lib.escapeShellArg staticSettings})"
    config="$(${lib.getExe pkgs.jq} -s ${lib.escapeShellArg jqOperation} --argjson dynamic "$dynamic" --argjson static "$static")"
    printf '%s\n' "$config" > ${lib.escapeShellArg path}
    unset config
  '';

  mergedSettings =
    cfg.userSettings
    // (lib.optionalAttrs (builtins.length cfg.extensions > 0) {
      # this part by @cmacrae
      auto_install_extensions = lib.genAttrs cfg.extensions (_: true);
    });
in
{
  meta.maintainers = [ lib.hm.maintainers.libewa ];

  options = {
    # TODO: add vscode option parity (installing extensions, configuring
    # keybinds with nix etc.)
    programs.zed-editor = {
      enable = lib.mkEnableOption "Zed, the high performance, multiplayer code editor from the creators of Atom and Tree-sitter";

      package = lib.mkPackageOption pkgs "zed-editor" { nullable = true; };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression "[ pkgs.nixd ]";
        description = "Extra packages available to Zed.";
      };

      userSettings = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            features = {
              copilot = false;
            };
            telemetry = {
              metrics = false;
            };
            vim_mode = false;
            ui_font_size = 16;
            buffer_font_size = 16;
          }
        '';
        description = ''
          Configuration written to Zed's {file}`settings.json`.
        '';
      };

      userKeymaps = mkOption {
        type = jsonFormat.type;
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

      extensions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''
          [ "swift" "nix" "xy-zed" ]
        '';
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
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) (
      if cfg.extraPackages != [ ] then
        [
          (pkgs.symlinkJoin {
            name = "${lib.getName cfg.package}-wrapped-${lib.getVersion cfg.package}";
            paths = [ cfg.package ];
            preferLocalBuild = true;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/zeditor \
                --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
            '';
          })
        ]
      else
        [ cfg.package ]
    );

    home.file = mkIf (cfg.installRemoteServer && (cfg.package ? remote_server)) (
      let
        inherit (cfg.package) version remote_server;
        binaryName = "zed-remote-server-stable-${version}";
      in
      {
        ".zed_server/${binaryName}".source = lib.getExe' remote_server binaryName;
      }
    );

    home.activation = mkMerge [
      (mkIf (mergedSettings != { }) {
        zedSettingsActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          impureConfigMerger "{}" "$dynamic * $static" "${config.xdg.configHome}/zed/settings.json" (
            jsonFormat.generate "zed-user-settings" mergedSettings
          )
        );
      })
      (mkIf (cfg.userKeymaps != [ ]) {
        zedKeymapActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          impureConfigMerger "[]"
            "$dynamic + $static | group_by(.context) | map(reduce .[] as $item ({}; . * $item))"
            "${config.xdg.configHome}/zed/keymap.json"
            (jsonFormat.generate "zed-user-keymaps" cfg.userKeymaps)
        );
      })
    ];

    xdg.configFile = lib.mapAttrs' (
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
    ) cfg.themes;

    assertions = [
      {
        assertion = cfg.extraPackages != [ ] -> cfg.package != null;
        message = "{option}programs.zed-editor.extraPackages requires non null {option}programs.zed-editor.package";
      }
    ];
  };
}
