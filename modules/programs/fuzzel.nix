{ config, lib, pkgs, ... }:

let

  inherit (lib) literalExpression mkEnableOption mkPackageOption mkOption mkIf;

  cfg = config.programs.fuzzel;

  iniFormat = pkgs.formats.ini { };

in {
  meta.maintainers = [ lib.maintainers.Scrumplex ];

  options.programs.fuzzel = {
    enable = mkEnableOption "fuzzel";

    package = mkPackageOption pkgs "fuzzel" { };

    settings = mkOption {
      type = iniFormat.type;
      default = { };
      example = literalExpression ''
        {
          main = {
            terminal = "''${pkgs.foot}/bin/foot";
            layer = "overlay";
          };
          colors.background = "ffffffff";
        }
      '';
      description = ''
        Configuration for fuzzel written to
        <filename>$XDG_CONFIG_HOME/fuzzel/fuzzel.ini</filename>. See
        <citerefentry><refentrytitle>fuzzel.ini</refentrytitle>
        <manvolnum>5</manvolnum></citerefentry> for a list of available options.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.fuzzel" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."fuzzel/fuzzel.ini" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "fuzzel.ini" cfg.settings;
    };
  };
}
