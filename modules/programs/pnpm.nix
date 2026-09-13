# https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/tools/pnpm/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.pnpm;

  # https://pnpm.io/11.x/settings#storedir
  defaultPnpmHome =
    if config.xdg.enable then
      "${config.xdg.dataHome}/pnpm"
    else if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/pnpm"
    else
      "${config.home.homeDirectory}/.local/share/pnpm";
in
{
  meta.maintainers = with lib.maintainers; [ typeparameter ];

  options = {
    programs.pnpm = {
      enable = lib.mkEnableOption "{command}`pnpm` user config";

      package = lib.mkPackageOption pkgs "pnpm" { nullable = true; };

      pnpmHome = mkOption {
        type = types.str;
        default = defaultPnpmHome;
        defaultText = lib.literalExpression ''
          if config.xdg.enable then
            "''${config.xdg.dataHome}/pnpm"
          else if pkgs.stdenv.hostPlatform.isDarwin then
            "''${config.home.homeDirectory}/Library/pnpm"
          else
            "''${config.home.homeDirectory}/.local/share/pnpm"
        '';
        example = lib.literalExpression "\${config.home.homeDirectory}/.pnpm";
        description = ''
          The pnpm home directory. This sets {env}`PNPM_HOME`, which controls
          the default locations of pnpm's package store, globally installed
          packages, and global executables.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = mkIf (cfg.package != null) [ cfg.package ];

      sessionVariables = {
        PNPM_HOME = cfg.pnpmHome;
      };

      sessionPath = [ "${cfg.pnpmHome}/bin" ];
    };
  };
}
