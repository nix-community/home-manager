{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.eclipse;
in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    programs.eclipse = {
      enable = lib.mkEnableOption "Eclipse";

      package = lib.mkPackageOption pkgs "eclipse" {
        default = [
          "eclipses"
          "eclipse-platform"
        ];
        example = "pkgs.eclipses.eclipse-java";
      };

      enableLombok = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether to enable the Lombok Java Agent in Eclipse. This is
          necessary to use the Lombok class annotations.
        '';
      };

      jvmArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "JVM arguments to use for the Eclipse process.";
      };

      plugins = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Plugins that should be added to Eclipse.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.eclipses.eclipseWithPlugins {
        eclipse = cfg.package;
        jvmArgs =
          cfg.jvmArgs
          ++ lib.optional cfg.enableLombok "-javaagent:${pkgs.lombok}/share/java/lombok.jar";
        plugins = cfg.plugins;
      })
    ];
  };
}
