{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.mr;
  listToValue = concatMapStringsSep ", " (generators.mkValueStringDefault { });
  iniFormat = pkgs.formats.ini { inherit listToValue; };
in {
  meta.maintainers = [ hm.maintainers.nilp0inter ];
  options.programs.mr = {
    enable =
      mkEnableOption "mr, a tool to manage all your version control repos";
    package = mkOption {
      type = types.package;
      default = pkgs.mr;
      defaultText = literalExpression "pkgs.mr";
      description = "The mr package to use.";
    };
    settings = mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to $HOME/.mrconfig
        See <link xlink:href="https://myrepos.branchable.com/"/>
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
    home.packages = [ cfg.package ];
    home.file.".mrconfig".source = iniFormat.generate ".mrconfig" cfg.settings;
  };
}

