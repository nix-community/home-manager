{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    makeBinPath
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optional
    optionals
    optionalAttrs
    recursiveUpdate
    escapeShellArg
    escapeShellArgs
    concatMapStringsSep
    types
    ;

  cfg = config.services.voxtype;
  toml = pkgs.formats.toml { };
  # Voxtype requires these whenever a config file exists.
  settings = recursiveUpdate {
    hotkey = { };
    audio = {
      device = "default";
      sample_rate = 16000;
      max_duration_secs = 60;
    };
    output = {
      mode = "type";
      fallback_to_clipboard = true;
    };
  } cfg.settings;

in
{
  meta.maintainers = [ lib.maintainers.marijanp ];

  options.services.voxtype = {
    enable = mkEnableOption "Voxtype speech-to-text daemon";

    package = mkPackageOption pkgs "voxtype" {
      example = "pkgs.voxtype-vulkan";
    };

    settings = mkOption {
      inherit (toml) type;
      default = { };
      example = {
        output = {
          mode = "type";
          fallback_to_clipboard = true;
        };
        whisper = {
          model = "base.en";
          language = "en";
        };
      };
      description = ''
        Voxtype configuration written to `$XDG_CONFIG_HOME/voxtype/config.toml`.
      '';
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--verbose" ];
      description = "Extra command-line arguments passed to `voxtype daemon`.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Environment variables for the Voxtype user service.";
    };

    x11.display = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = ":0";
      description = ''
        X11 display name to expose to the Voxtype user service.
      '';
    };

    wayland.display = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "wayland-1";
      description = ''
        Wayland display socket name to expose to the Voxtype user service.
      '';
    };

    loadModels = mkOption {
      type = types.listOf types.str;
      apply = builtins.filter (model: model != "");
      default = [ ];
      example = [ "base.en" ];
      description = ''
        Downloads the listed models with `voxtype setup --download` before starting
        the daemon.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
    ]
    ++ optionals (cfg.x11.display != null) [ pkgs.xclip ]
    ++ optionals (cfg.wayland.display != null) [
      pkgs.wl-clipboard
      pkgs.wtype
    ];

    xdg.configFile."voxtype/config.toml" = mkIf (cfg.settings != { }) {
      source = toml.generate "voxtype-config.toml" settings;
    };

    systemd.user.services.voxtype = {
      Unit = {
        Description = "Voxtype speech-to-text daemon";
        PartOf = [ "default.target" ];
        X-Restart-Triggers = mkIf (cfg.settings != { }) [
          "${config.xdg.configFile."voxtype/config.toml".source}"
        ];
      }
      // optionalAttrs (cfg.loadModels != [ ]) {
        Wants = [ "voxtype-model-loader.service" ];
        After = [ "voxtype-model-loader.service" ];
      };

      Service =
        let
          runtimePath = makeBinPath (
            [ pkgs.which ]
            ++ optionals (cfg.x11.display != null) [ pkgs.xclip ]
            ++ optionals (cfg.wayland.display != null) [
              pkgs.wl-clipboard
              pkgs.wtype
            ]
          );
        in
        {
          Type = "exec";
          ExecStart = "${getExe cfg.package} daemon ${escapeShellArgs cfg.extraArgs}";
          Restart = "on-failure";
          RestartSec = "5s";
          Environment = [
            "PATH=${runtimePath}"
            "XDG_RUNTIME_DIR=%t"
          ]
          ++ optional (cfg.x11.display != null) "DISPLAY=${cfg.x11.display}"
          ++ optional (cfg.wayland.display != null) "WAYLAND_DISPLAY=${cfg.wayland.display}"
          ++ mapAttrsToList (name: value: "${name}=${value}") cfg.environment;
        };

      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services.voxtype-model-loader = mkIf (cfg.loadModels != [ ]) {
      Unit = {
        Description = "Download Voxtype models";
        Before = [ "voxtype.service" ];
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" ];
      };

      Service =
        let
          modelLoaderScript = pkgs.writeShellScript "voxtype-model-loader" ''
            set -euo pipefail
            tmp="$(${pkgs.coreutils}/bin/mktemp -d /tmp/voxtype-model-loader.XXXXXX)"
            trap '${pkgs.coreutils}/bin/rm -rf "$tmp"' EXIT

            ${concatMapStringsSep "\n" (
              model:
              "XDG_CONFIG_HOME=\"$tmp\" ${getExe cfg.package} setup --download --model ${escapeShellArg model} --no-post-install"
            ) cfg.loadModels}
          '';
        in
        {
          Type = "oneshot";
          ExecStart = modelLoaderScript;
          Restart = "on-failure";
          RestartSec = "30s";
        };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
