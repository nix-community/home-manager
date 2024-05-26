{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zed-editor;
in
{
  options = {
    programs.zed-editor = {
      enable = mkEnableOption "Zed, the high performance, multiplayer code editor from the creators of Atom and Tree-sitter";
      package = mkOption {
        type = types.package;
        default = pkgs.zed-editor;
        defaultText = literalExpression "pkgs.zed-editor";
        description = ''
          Another package to install instead of zed
        '';
    };
    config = mkIf cfg.enable {
      home.packages = [ cfg.package ];
    };
  };
}
