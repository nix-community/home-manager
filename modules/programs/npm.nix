# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/npm.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.npm;
in
{
  meta.maintainers = with lib.maintainers; [ mirkolenz ];

  options = {
    programs.npm = {
      enable = lib.mkEnableOption "{command}`npm` user config";

      package = lib.mkPackageOption pkgs [ "nodePackages" "npm" ] {
        example = "nodePackages_13_x.npm";
        nullable = true;
      };

      npmrc = lib.mkOption {
        type = lib.types.lines;
        description = ''
          The user-specific npm configuration.
          See <https://docs.npmjs.com/misc/config>.
        '';
        default = ''
          prefix = ''${HOME}/.npm
        '';
        example = ''
          prefix = ''${HOME}/.npm
          https-proxy=proxy.example.com
          init-license=MIT
          init-author-url=https://www.npmjs.com/
          color=true
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable {
    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];
      file.".npmrc" = lib.mkIf (cfg.npmrc != "") {
        text = cfg.npmrc;
      };
      sessionVariables = lib.mkIf (cfg.npmrc != "") {
        NPM_CONFIG_USERCONFIG = "${config.home.homeDirectory}/.npmrc";
      };
    };
  };
}
