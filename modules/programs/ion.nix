{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.ion;

  aliasesStr = concatStringsSep "\n"
    (mapAttrsToList (k: v: "alias ${k} = ${escapeShellArg v}")
      cfg.shellAliases);
in {
  meta.maintainers = [ maintainers.jo1gi ];

  options.programs.ion = {
    enable = mkEnableOption "the Ion Shell. Compatible with Redox and Linux";

    package = mkOption {
      type = types.package;
      default = pkgs.ion;
      defaultText = literalExpression "pkgs.ion";
      description = ''
        The ion package to install. May be used to change the version.
      '';
    };

    initExtra = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Ion script which is called during ion initialization
      '';
    };

    shellAliases = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = literalExpression ''
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

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."ion/initrc".text = ''
      # Aliases
      ${aliasesStr}

      ${cfg.initExtra}
    '';
  };
}
