{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.mr;

  listToValue = concatMapStringsSep ", " (generators.mkValueStringDefault { });

  iniFormat = pkgs.formats.ini { inherit listToValue; };

in {
  meta.maintainers = [ hm.maintainers.nilp0inter ];

  options.programs.mr = {
    enable = mkEnableOption
      "mr, a tool to manage all your version control repositories";

    package = mkPackageOption pkgs "mr" { nullable = true; };

    settings = mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$HOME/.mrconfig`
        See <https://myrepos.branchable.com/>
        for an example configuration.
      '';
      example = literalExpression ''
        {
          foo = {
            checkout = "git clone git@github.com:joeyh/foo.git";
            update = "git pull --rebase";
          };
          ".local/share/password-store" = {
            checkout = "git clone git@github.com:myuser/password-store.git";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    home.file.".mrconfig".source = iniFormat.generate ".mrconfig" cfg.settings;
  };
}

