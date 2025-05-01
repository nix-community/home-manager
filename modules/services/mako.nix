{
  config,
  lib,
  pkgs,
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

  cfg = config.services.mako;

  generateConfig = lib.generators.toKeyValue { };
in
{
  meta.maintainers = [ lib.maintainers.onny ];

  imports = [ (lib.mkRenamedOptionModule [ "programs" "mako" ] [ "services" "mako" ]) ];

  options.services.mako = {
    enable = mkEnableOption "mako";
    package = mkPackageOption pkgs "mako" { };
    settings = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = ''
        {
          actions = "true";
          anchor = "top-right";
          backgroundColor = "#000000";
          borderColor = "#FFFFFF";
          borderRadius = "0";
          defaultTimeout = "0";
          font = "monospace 10";
          height = "100";
          width = "300";
          icons = "true";
          ignoreTimeout = "false";
          layer = "top";
          margin = "10";
          markup = "true";
        }
      '';
      description = ''
        Configuration settings for mako. All available options can be found
        here: <https://github.com/emersion/mako/blob/master/doc/mako.5.scd>.
      '';
    };
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        [mode=do-not-disturb]
        invisible=1

        [app-name="Google Chrome"]
        max-visible=1
        history=0
      '';
      description = ''
        Extra configuration lines to be appended at the end of the file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mako" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."mako/config" = mkIf (cfg.settings != { }) {
      onChange = "${cfg.package}/bin/makoctl reload || true";
      text = (generateConfig cfg.settings) + "\n${cfg.extraConfig}";
    };
  };
}
