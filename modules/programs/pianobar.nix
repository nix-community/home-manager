{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    literalExpression
    ;

  inherit (lib.types)
    nonEmptyStr
    submodule
    ;

  inherit (pkgs.formats)
    keyValue
    ;

  keyValueFormat = keyValue { };

  cfg = config.programs.pianobar;
in
{
  meta.maintainers = [
    # lib.maintainers.S0AndS0
    ## TODO: Trade above for below when `node.nixpkgs.locked.rev` is at or beyond
    ##       4d48a4e93b9ffbd291b2d9ca3315848e27eed800
    {
      name = "S0AndS0";
      email = "S0AndS0@digital-mercenaries.com";
      github = "S0AndS0";
      githubId = 4116150;
      matrix = "@s0ands0:matrix.org";
    }
  ];

  options.programs.pianobar = {
    enable = mkEnableOption "Enable pianobar";

    package = mkPackageOption pkgs "pianobar" {
      nullable = true;
    };

    settings = mkOption {
      type = submodule {
        freeformType = keyValueFormat.type;
        options = {
          user = mkOption {
            description = "Username or emaill address for Pandora music service authentication";
            example = ''"groovy-tunes@example.com"'';
            type = nonEmptyStr;
          };

          password_command = mkOption {
            description = "Command pianobar will use to access password for Pandora music service authentication";
            example = ''"cat /run/secrets/pianobar/groovy-tunes"'';
            type = nonEmptyStr;
          };
        };
      };

      default = { };

      description = ''
        Apply configurations for `pianobar` via key/value attributes.

        Note; it is recommended to use `sops-nix`, or similar, secrets
        management solution for providing
        `programs.pianobar.settings.password_command` value.
      '';

      example = literalExpression ''
        {
          programs.pianobar = {
            enable = true;
            settings = {
              user = "groovy-tunes@example.com";
              password_command = "cat /run/secrets/pianobar/groovy-tunes";
            };
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."pianobar/config" = lib.mkIf (cfg.settings != { }) {
      source = keyValueFormat.generate "pianobar-config" cfg.settings;
    };

    home.packages = mkIf (cfg.package != null) [
      cfg.package
    ];
  };
}
