{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pylint;
  listToValue =
    lib.concatMapStringsSep ", " (lib.generators.mkValueStringDefault { });
  iniFormat = pkgs.formats.ini { inherit listToValue; };
in {
  meta.maintainers = [ lib.hm.maintainers.florpe ];
  options.programs.pylint = {
    enable = lib.mkEnableOption "the pylint Python linter";
    package = lib.mkPackageOption pkgs [ "python3Packages" "pylint" ] { };
    settings = lib.mkOption {
      type = iniFormat.type;
      default = { };
      defaultText = lib.literalExpression "{}";
      description = "The pylint configuration.";
    };
  };
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.file.".pylintrc".source = iniFormat.generate "pylintrc" cfg.settings;
  };
}
