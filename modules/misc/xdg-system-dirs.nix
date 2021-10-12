{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xdg.systemDirs;

  configDirs = concatStringsSep ":" cfg.config;

  dataDirs = concatStringsSep ":" cfg.data;

in {
  meta.maintainers = with maintainers; [ tadfisher ];

  options.xdg.systemDirs = {
    config = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = literalExpression ''[ "/etc/xdg" ]'';
      description = ''
        Directory names to add to <envar>XDG_CONFIG_DIRS</envar>
        in the user session.
      '';
    };

    data = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = literalExpression ''[ "/usr/share" "/usr/local/share" ]'';
      description = ''
        Directory names to add to <envar>XDG_DATA_DIRS</envar>
        in the user session.
      '';
    };
  };

  config = mkMerge [
    (mkIf (cfg.config != [ ] || cfg.data != [ ]) {
      assertions = [
        (hm.assertions.assertPlatform "xdg.systemDirs" pkgs platforms.linux)
      ];
    })

    (mkIf (cfg.config != [ ]) {
      home.sessionVariables.XDG_CONFIG_DIRS =
        "${configDirs}\${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}";

      systemd.user.sessionVariables.XDG_CONFIG_DIRS =
        "${configDirs}\${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}";
    })

    (mkIf (cfg.data != [ ]) {
      home.sessionVariables.XDG_DATA_DIRS =
        "${dataDirs}\${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}";

      systemd.user.sessionVariables.XDG_DATA_DIRS =
        "${dataDirs}\${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}";
    })
  ];
}
