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
  defaultHomeDir =
    if pkgs.stdenv.isDarwin && !config.xdg.enable then
      "${config.home.homeDirectory}/Library/pnpm"
    else
      "${config.xdg.dataHome}/pnpm";
in
{
  meta.maintainers = with lib.maintainers; [ typeparameter ];

  options = {
    programs.pnpm = {
      enable = lib.mkEnableOption "{command}`pnpm` user config";

      package = lib.mkPackageOption pkgs "pnpm" { nullable = true; };

      homeDir = mkOption {
        type = types.str;
        default = defaultHomeDir;
        defaultText = lib.literalExpression ''
          if pkgs.stdenv.isDarwin && !config.xdg.enable then
            "''${config.home.homeDirectory}/Library/pnpm"
          else
            "''${config.xdg.dataHome}/pnpm"
        '';
        example = lib.literalExpression "\${config.home.homeDirectory}/.pnpm";
        description = ''
          The pnpm home directory. Changing this sets {env}`PNPM_HOME`, which
          controls the default locations of pnpm's package store, globally
          installed packages, and global executables.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = mkIf (cfg.package != null) [ cfg.package ];

      sessionVariables = lib.optionalAttrs (cfg.homeDir != defaultHomeDir) {
        PNPM_HOME = cfg.homeDir;
      };

      sessionPath = [ "${cfg.homeDir}/bin" ];
    };
  };
}
