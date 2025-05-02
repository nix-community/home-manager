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
in
{
  options.programs.gimp = {
    enable = mkEnableOption "gimp";
    package = mkPackageOption pkgs "gimp-with-plugins" { nullable = true; };
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
    warnings = lib.optional (cfg.package == null && cfg.plugins != [ ]) ''
      You have configured `plugins` for Gimp, but havee not set `package`.

      The listed plugins will not be installed.
    '';

    home.packages = mkIf (cfg.package != null) [ cfg.package ] ++ cfg.plugins;
  };
}
