{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.crossover;
in
{
  meta.maintainers = [ lib.maintainers.rapiteanu ];

  options.programs.crossover = {
    enable = lib.mkEnableOption "CrossOver";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix {
        homeDir = config.home.homeDirectory;
      };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { homeDir = config.home.homeDirectory; }";
      description = ''
        The CrossOver package to use. The default is a repackaging of the
        CodeWeavers Fedora rpm with the fixes needed to run on NixOS (see
        the package file for the full list). The package is unfree, so
        building it requires `nixpkgs.config.allowUnfree = true` (or
        `NIXPKGS_ALLOW_UNFREE=1`).
      '';
    };

    license = {
      file = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "./license.txt";
        description = ''
          Path to the CrossOver license file (`license.txt`), as produced by
          a normal CrossOver registration. If both `file` and `signature`
          are set, CrossOver starts unlocked without any interactive login.
        '';
      };

      signature = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "./license.sha256";
        description = ''
          Path to the SHA-256 signature of the license file
          (`license.sha256`), as produced by a normal CrossOver
          registration.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # The package installs the `crossover` GUI, the wine launchers and the
    # desktop entry; putting it in home.packages also makes `wine-crossover`
    # resolvable on $PATH, which the .lnk launchers rely on.
    home.packages = [ cfg.package ];

    home.file.".cxoffice/etc/license.txt" = lib.mkIf (cfg.license.file != null) {
      source = cfg.license.file;
    };
    home.file.".cxoffice/etc/license.sha256" = lib.mkIf (cfg.license.signature != null) {
      source = cfg.license.signature;
    };
  };
}
