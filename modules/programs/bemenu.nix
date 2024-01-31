{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bemenu;

in {
  meta.maintainers = [ hm.maintainers.omernaveedxyz ];

  options.programs.bemenu = {
    enable = mkEnableOption "bemenu";

    package = mkPackageOption pkgs "bemenu" { };

    settings = mkOption {
      type = with types; attrsOf (oneOf [ str number bool ]);
      default = { };
      example = literalExpression ''
        {
          line-height = 28;
          prompt = "open";
          ignorecase = true;
          fb = "#1e1e2e";
          ff = "#cdd6f4";
          nb = "#1e1e2e";
          nf = "#cdd6f4";
          tb = "#1e1e2e";
          hb = "#1e1e2e";
          tf = "#f38ba8";
          hf = "#f9e2af";
          af = "#cdd6f4";
          ab = "#1e1e2e";
          width-factor = 0.3;
        }
      '';
      description =
        "Configuration options for bemenu. See {manpage}`bemenu(1)`.";
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "programs.bemenu" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    home.sessionVariables = mkIf (cfg.settings != { }) {
      BEMENU_OPTS = cli.toGNUCommandLineShell { } cfg.settings;
    };
  };
}
