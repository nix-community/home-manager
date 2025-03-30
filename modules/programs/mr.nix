{ config, lib, pkgs, ... }:
let
  cfg = config.programs.mr;

  listToValue =
    lib.concatMapStringsSep ", " (lib.generators.mkValueStringDefault { });

  iniFormat = pkgs.formats.ini { inherit listToValue; };
in {
  meta.maintainers = [ lib.hm.maintainers.nilp0inter ];

  options.programs.mr = {
    enable = lib.mkEnableOption
      "mr, a tool to manage all your version control repositories";

    package = lib.mkPackageOption pkgs "mr" { nullable = true; };

    settings = lib.mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$HOME/.mrconfig`
        See <https://myrepos.branchable.com/>
        for an example configuration.
      '';
      example = lib.literalExpression ''
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

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    home.file.".mrconfig".source = iniFormat.generate ".mrconfig" cfg.settings;
  };
}

