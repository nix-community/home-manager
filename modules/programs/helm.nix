{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.helm;

  enableXdgDir = !pkgs.stdenv.hostPlatform.isDarwin || config.xdg.enable;
in {
  meta.maintainers = [ hm.maintainers.folliehiyuki ];

  options.programs.helm = {
    enable = mkEnableOption "helm";

    package = mkPackageOption pkgs "helm" { default = [ "kubernetes-helm" ]; };

    plugins = mkOption {
      type = with types; attrsOf path;
      default = { };
      description = ''
        Helm plugins to be installed.
        Values should be a path containing a top-level `plugin.yaml` file.
        Will be linked to {file}`$XDG_DATA_HOME/helm/plugins/<name>/`.
      '';
      example = literalExpression ''
        {
          custom = ./custom;
          diff = ${pkgs.kubernetes-helmPlugins.helm-diff}/helm-diff;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.dataFile = mkIf enableXdgDir (mapAttrs'
      (name: value: nameValuePair "helm/plugins/${name}" { source = value; })
      cfg.plugins);

    home.file = mkIf (!enableXdgDir) (mapAttrs' (name: value:
      nameValuePair "Library/helm/plugins/${name}" { source = value; })
      cfg.plugins);
  };
}
