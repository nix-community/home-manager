{ pkgs, config, lib, ... }:
let
  inherit (lib)
    mkOption mkEnableOption mkIf maintainers literalExpression types
    mkRemovedOptionModule versionAtLeast;

  cfg = config.services.espanso;
  espansoVersion = cfg.package.version;

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
        default = pkgs.espanso;
        defaultText = literalExpression "pkgs.espanso";
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
    assertions = [{
      assertion = versionAtLeast espansoVersion "2";
      message = ''
        The services.espanso module only supports Espanso version 2 or later.
      '';
    }];

    home.packages = [ cfg.package ];

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
      Unit = { Description = "Espanso: cross platform text expander in Rust"; };
      Service = {
        Type = "exec";
        ExecStart = "${cfg.package}/bin/espanso daemon";
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
