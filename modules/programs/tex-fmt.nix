{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.tex-fmt;
  configPath = "${config.xdg.configHome}/tex-fmt/tex-fmt.toml";
in {
  meta.maintainers = [ maintainers.wgunderwood ];

  options = {
    programs.tex-fmt = {
      enable = mkEnableOption "tex-fmt";
      package = mkPackageOption pkgs "tex-fmt" { };
      options = mkOption {
        default = { };
        type = with types; attrsOf (oneOf [ str bool int ]);
        description = ''
          List of options to pass to tex-fmt.

          See <https://github.com/WGUNDERWOOD/tex-fmt/blob/master/tex-fmt.toml>
          for an example configuration.
        '';
        example = {
          usetabs = true;
          wraplen = 70;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home = mkMerge [
      { packages = [ cfg.package ]; }
      (mkIf (cfg.options != [ ]) {
        file."${configPath}".text = lib.concatLines cfg.options;
      })
    ];
  };
}
