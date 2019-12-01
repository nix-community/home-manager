{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.readline;
in
{
  options.programs.readline = {
    enable = mkEnableOption "readline";

    bindings = mkOption {
      default = {};
      type = types.attrsOf types.str;
      example = { "\C-h" = "backward-kill-word"; };
      description = "Readline bindings";
    };

    includeSystem = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to include the system-wide config";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Config lines appended to the end unchanged. Useful for configuration not yet supported by home-manager.";
    };
  };
  config = mkIf cfg.enable {
    home.packages = [ pkgs.readline ];
    home.file.".inputrc".text =
    let
      includeSystemStr = if cfg.includeSystem then "$include /etc/inputrc" else "";
      bindingsStr = concatStringsSep "\n" (
        mapAttrsToList (k: v: "\"${k}\": ${v}") cfg.bindings
      );
    in
      ''
        ${includeSystemStr}
        ${bindingsStr}
        ${cfg.extraConfig}
      '';
  };
}
