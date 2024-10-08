{ pkgs, config, lib, ... }:
let
  inherit (lib)
    mkOption mkEnableOption mkIf maintainers literalExpression types
    mkRemovedOptionModule versionAtLeast;

  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

  cfg = config.services.espanso;
  espansoVersion = cfg.package.version;

  package-bin = if isLinux then
    pkgs.writeShellScriptBin "espanso" ''
      if [ -n "$WAYLAND_DISPLAY" ]; then
        ${lib.meta.getExe cfg.package-wayland} "$@"
      else
        ${lib.meta.getExe cfg.package} "$@"
      fi
    ''
  else
    cfg.package;

  yaml = pkgs.formats.yaml { };
in {
  imports = [
    (mkRemovedOptionModule [ "services" "espanso" "settings" ]
      "Use services.espanso.configs and services.espanso.matches instead.")
  ];
  meta.maintainers = [
    maintainers.lucasew
    maintainers.bobvanderlinden
    lib.hm.maintainers.liyangau
    maintainers.n8henrie
  ];
  options = {
    services.espanso = {
      enable = mkEnableOption "Espanso: cross platform text expander in Rust";

      package = mkOption {
        type = types.package;
        description = "Which espanso package to use";
        default = if isDarwin then
          pkgs.espanso
        else if cfg.x11Support then
          pkgs.espanso
        else
          pkgs.espanso-wayland;
        defaultText = literalExpression "pkgs.espanso";
      };

      package-wayland = mkOption {
        type = types.package;
        description = "Which espanso package to use when running under wayland";
        default =
          if cfg.waylandSupport then pkgs.espanso-wayland else pkgs.espanso;
        defaultText = literalExpression "pkgs.espanso-wayland";
      };

      x11Support = mkOption {
        type = types.bool;
        description = "Whether to enable x11 support on linux";
        default = isLinux;
        defaultText = literalExpression "enabled on linux";
      };

      waylandSupport = mkOption {
        type = types.bool;
        description = "Whether to enable wayland support on linux";
        default = isLinux;
        defaultText = literalExpression "enabled on linux";
      };

      configs = mkOption {
        type = yaml.type;
        default = { default = { }; };
        example = literalExpression ''
          {
            default = {
              show_notifications = false;
            };
            vscode = {
              filter_title = "Visual Studio Code$";
              backend = "Clipboard";
            };
          };
        '';
        description = ''
          The Espanso configuration to use. See
          <https://espanso.org/docs/configuration/basics/>
          for a description of available options.
        '';
      };

      matches = mkOption {
        type = yaml.type;
        default = { default.matches = [ ]; };
        example = literalExpression ''
          {
            base = {
              matches = [
                {
                  trigger = ":now";
                  replace = "It's {{currentdate}} {{currenttime}}";
                }
                {
                  trigger = ":hello";
                  replace = "line1\nline2";
                }
                {
                  regex = ":hi(?P<person>.*)\\.";
                  replace = "Hi {{person}}!";
                }
              ];
            };
            global_vars = {
              global_vars = [
                {
                  name = "currentdate";
                  type = "date";
                  params = {format = "%d/%m/%Y";};
                }
                {
                  name = "currenttime";
                  type = "date";
                  params = {format = "%R";};
                }
              ];
            };
          };
        '';
        description = ''
          The Espanso matches to use. See
          <https://espanso.org/docs/matches/basics/>
          for a description of available options.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = versionAtLeast espansoVersion "2";
        message = ''
          The services.espanso module only supports Espanso version 2 or later.
        '';
      }
      {
        assertion = isDarwin != (cfg.x11Support || cfg.waylandSupport);
        message = ''
          In services.espanso at least x11 or wayland support must be enabled on linux.
        '';
      }
    ];

    # obviously conflicting to have cfg.package and cfg.package-wayland
    home.packages = [ package-bin ];

    xdg.configFile = let
      configFiles = lib.mapAttrs' (name: value: {
        name = "espanso/config/${name}.yml";
        value = { source = yaml.generate "${name}.yml" value; };
      }) cfg.configs;
      matchesFiles = lib.mapAttrs' (name: value: {
        name = "espanso/match/${name}.yml";
        value = { source = yaml.generate "${name}.yml" value; };
      }) cfg.matches;
    in configFiles // matchesFiles;

    systemd.user.services.espanso = {
      Unit = {
        Description = "Espanso: cross platform text expander in Rust";
      };
      Service = {
        Type = "exec";
        ExecStart = "${lib.meta.getExe package-bin} daemon";
        Restart = "on-failure";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };

    launchd.agents.espanso = {
      enable = true;
      config = {
        ProgramArguments = [ "${cfg.package}/bin/espanso" "launcher" ];
        EnvironmentVariables.PATH =
          "${cfg.package}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        RunAtLoad = true;
      };
    };
  };
}
