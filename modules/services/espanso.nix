{ pkgs, config, lib, ... }:
let
  inherit (lib)
    mkOption mkEnableOption mkIf maintainers literalExpression types platforms;

  inherit (lib.hm.assertions) assertPlatform;

  cfg = config.services.espanso;

  yaml = pkgs.formats.yaml { };
in {
  meta.maintainers = with maintainers; [ lucasew ];
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
          configs = {
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
          <link xlink:href="https://espanso.org/docs/configuration/basics/"/>
          for a description of available options.
        '';
      };

      matches = mkOption {
        type = yaml.type;
        default = { default.matches = [ ]; };
        example = literalExpression ''
          matches = {
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
          <link xlink:href="https://espanso.org/docs/matches/basics/"/>
          for a description of available options.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [ (assertPlatform "services.espanso" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    xdg.configFile = let
      configFiles = lib.mapAttrs' (name: value: {
        name = "espanso/config/${name}.yml";
        value = { source = yaml.generate "${name}.yml" value; };
      }) config.services.espanso.configs;
      matchesFiles = lib.mapAttrs' (name: value: {
        name = "espanso/match/${name}.yml";
        value = { source = yaml.generate "${name}.yml" value; };
      }) config.services.espanso.matches;
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
  };
}
