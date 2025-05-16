{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.gimp;
  defaultPackage = if cfg.withPlugins then "gimp-with-plugins" else "gimp";
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.gimp = {
    enable = mkEnableOption "gimp";
    package = mkPackageOption pkgs defaultPackage { nullable = true; };
    withPlugins = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whatever to install Gimp with plugins enabled.
      '';
    };
    plugins = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = ''
        with pkgs.gimpPlugins; [ gmic bimp fourier ];
      '';
      description = ''
        List of Gimp plugins to install. Requires Gimp with plugins.
      '';
    };
  };

  config = mkIf cfg.enable {
    warnings = lib.optional ((cfg.package == null || cfg.withPlugins == false) && cfg.plugins != [ ]) ''
      You have configured `plugins` for Gimp, but have either not set `package` or have `withPlugins` set to false.

      The listed plugins will not be installed.
    '';

    home.packages = mkIf (cfg.package != null) ([ cfg.package ] ++ cfg.plugins);
  };
}
