{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.cliamp;
  tomlFormat = pkgs.formats.toml { };
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    types
    ;
in
{
  meta.maintainers = [ lib.maintainers.rachitvrma ];

  options.programs.cliamp = {
    enable = mkEnableOption "cliamp, a retro terminal music player inspired by Winamp";
    package = mkPackageOption pkgs "cliamp" { nullable = true; };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        eq = [
          "-2"
          "0"
          "0"
          "0"
          "0"
          "0"
          "0"
          "0"
          "0"
          "0"
        ];
        eq_preset = "Custom";
        theme = "";
        visualizer = "Bricks";
        ytmusic = {
          enabled = true;
        };
      };

      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/cliamp/config.toml`.

        See
        <https://whiterose.org.contextowl.co/docs/cliamp>
        for the full list of options.
      '';
    };
    themes = mkOption {
      type = types.attrsOf (
        types.oneOf [
          tomlFormat.type
        ]
      );
      default = { };
      example = {
        solarized = {
          accent = "#268bd2";
          bright_fg = "#eee8d5";
          fg = "#839496";
          green = "#859900";
          yellow = "#b58900";
          red = "#dc322f";
        };
      };
      description = ''
        Each theme is written to {file}`$XDG_CONFIG_HOME/cliamp/themes/NAME.toml`.
        See <https://whiterose.org.contextowl.co/docs/cliamp/themes> for more information.
      '';
    };
    radios = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        station = [
          {
            name = "Jazz FR";
            url = "https://jazz.example.com/stream";
          }
          {
            name = "Ambient Radio";
            url = "https://ambient.example.com/stream.m3u";
          }
        ];
      };
      description = ''
        Add your own stations to {file}`$XDG_CONFIG_HOME/cliamp/radios.toml`.
        See <https://github.com/bjarneo/cliamp/blob/main/docs/configuration.md#custom-radio-stations>
      '';
    };

    systemd = {
      enable = mkEnableOption "a systemd user service for cliamp";

      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "--auto-play"
          "--playlist"
          "Lofi"
        ];
        description = ''
          Extra command-line flags appended after `cliamp --daemon`
          in the generated systemd user service.

          See <https://whiterose.org.contextowl.co/docs/cliamp/headless-daemon-mode> for
          more details.

          Note: these are passed directly to `ExecStart`, which is not
          shell-interpreted — `~` is not expanded. Use an absolute path,
          or a systemd specifier like `%h` for the user's home directory
          (e.g. `"%h/Music"`); see systemd.unit(5) § Specifiers.
        '';
      };
    };
    plugins = mkOption {
      type =
        with types;
        attrsOf (
          either package (
            addCheck path (
              p:
              (lib.pathIsDirectory p && lib.pathExists (p + "/init.lua"))
              || (lib.hasSuffix ".lua" (toString p) && lib.pathIsRegularFile p)
            )
          )
        );
      default = { };
      example = lib.literalExpression ''
        {
          block-burst = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/AlexZeitler/cliamp-plugin-block-burst/master/block-burst.lua";
            hash = "sha256-CK/NlavSzePrOFop6tGLbp5S0aTokb6ZcDNxpvzsxxo=";
          };
          cliamp-single-file = ../plugins/visualizer.lua;
          cliamp-local-dir = ../plugins/lastfm-scrobbler;
        }
      '';
      description = ''
        Plugins to install in {file}`XDG_CONFIG_HOME/cliamp/plugins`.

        Accepts either a package/derivation (e.g. `pkgs.fetchFromGitHub { ... }`)
        or a local path. A local path may point at a single `.lua` file, or
        at a directory containing an `init.lua` entry point — cliamp loads
        only `init.lua` from a plugin directory, so a directory without one
        is rejected at evaluation time rather than silently doing nothing.

        Note on trust: cliamp requires every plugin's contents to be
        approved with `cliamp plugins trust <name>` before it will run
        them, and re-approval is required whenever the content changes
        (see cliamp's plugin docs). This module only places files under
        {file}`plugins/`; it does not and cannot manage
        {file}`plugins/.trust.json` for you. After a rebuild that adds or
        changes a plugin here, you will need to re-run
        `cliamp plugins trust <name>` yourself.

        Package-based plugins (branch above) are not checked for shape at
        evaluation time, since a derivation's output does not exist on
        disk until it is built.

        See <https://whiterose.org.contextowl.co/docs/cliamp/lua-plugins>
        for more details.
      '';
    };
  };
  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = lib.mkMerge [
      {
        "cliamp/config.toml" = mkIf (cfg.settings != { }) {
          source = tomlFormat.generate "cliamp-config" cfg.settings;
        };
      }
      {
        "cliamp/radios.toml" = mkIf (cfg.radios != { }) {
          source = tomlFormat.generate "cliamp-radios" cfg.radios;
        };
      }
      (lib.mapAttrs' (
        name: value:
        lib.nameValuePair "cliamp/themes/${name}.toml" {
          source = tomlFormat.generate "cliamp-theme-${name}" value;
        }
      ) cfg.themes)
      (lib.mapAttrs' (
        name: value:
        lib.nameValuePair "cliamp/plugins/${name}${lib.optionalString (!lib.pathIsDirectory value) ".lua"}"
          {
            source = value;
          }
      ) cfg.plugins)
    ];

    systemd.user.services.cliamp = mkIf cfg.systemd.enable {
      Unit = {
        Description = "cliamp headless music player";
      };
      Service = {
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe cfg.package)
            "--daemon"
          ]
          ++ cfg.systemd.extraFlags
        );
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
