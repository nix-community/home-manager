{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.eww;
in
{
  meta.maintainers = [ lib.hm.maintainers.mainrs ];

  imports =
    map
      (
        shell:
        lib.mkRemovedOptionModule [
          "programs"
          "eww"
          "enable${shell}Integration"
        ] "This option is no longer necessary. Shell completions are now installed with eww by nixpkgs."
      )
      [
        "Bash"
        "Zsh"
        "Fish"
      ];

  options.programs.eww = {
    enable = lib.mkEnableOption "eww";

    package = lib.mkPackageOption pkgs "eww" { };

    configDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./eww-config-dir";
      description = ''
        The directory that gets symlinked to
        {file}`$XDG_CONFIG_HOME/eww`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg = mkIf (cfg.configDir != null) { configFile."eww".source = cfg.configDir; };
  };
}
