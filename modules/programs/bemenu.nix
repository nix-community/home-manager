{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.bemenu;
in
{
  meta.maintainers = [ ];

  options.programs.bemenu = {
    enable = lib.mkEnableOption "bemenu";

    package = lib.mkPackageOption pkgs "bemenu" { nullable = true; };

    settings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          str
          number
          bool
        ]);
      default = { };
      example = lib.literalExpression ''
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
      description = "Configuration options for bemenu. See {manpage}`bemenu(1)`.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.bemenu" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.sessionVariables = lib.mkIf (cfg.settings != { }) {
      # Not using `toCommandLineShellGNU` since it doesn't handle short form options with empty strings
      # https://github.com/nix-community/home-manager/issues/8544
      BEMENU_OPTS = lib.cli.toCommandLineShell (optionName: {
        option = if builtins.stringLength optionName > 1 then "--${optionName}" else "-${optionName}";
        sep = null;
        explicitBool = false;
      }) cfg.settings;
    };
  };
}
