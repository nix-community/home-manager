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

      settings = mkOption {
        type = yaml.type;
        default = { matches = [ ]; };
        example = literalExpression ''
          {
            matches = [
              { # Simple text replacement
                trigger = ":espanso";
                replace = "Hi there!";
              }
              { # Dates
                trigger = ":date";
                replace = "{{mydate}}";
                vars = [{
                  name = "mydate";
                  type = "date";
                  params = { format = "%m/%d/%Y"; };
                }];
              }
              { # Shell commands
                trigger = ":shell";
                replace = "{{output}}";
                vars = [{
                  name = "output";
                  type = "shell";
                  params = { cmd = "echo Hello from your shell"; };
                }];
              }
            ];
          }
        '';
        description = ''
          The Espanso configuration to use. See
          <link xlink:href="https://espanso.org/docs/configuration/"/>
          for a description of available options.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [ (assertPlatform "services.espanso" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    xdg.configFile."espanso/default.yml".source =
      yaml.generate "espanso-default.yml" cfg.settings;

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
