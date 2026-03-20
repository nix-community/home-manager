{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.programs.ion;

  aliasesStr = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "alias ${k} = ${lib.escapeShellArg v}") cfg.shellAliases
  );
in
{
  meta.maintainers = [ lib.maintainers.jo1gi ];

  options.programs.ion = {
    enable = lib.mkEnableOption "the Ion Shell. Compatible with Redox and Linux";

    package = lib.mkPackageOption pkgs "ion" { };

    initExtra = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Ion script which is called during ion initialization.
      '';
    };

    shellAliases = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = lib.literalExpression ''
        {
          g = "git";
        }
      '';
      description = ''
        An attribute set that maps aliases (the top level attribute names
        in this option) to command strings or directly to build outputs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."ion/initrc".text = ''
      # Aliases
      ${aliasesStr}

      ${cfg.initExtra}
    '';
  };
}
