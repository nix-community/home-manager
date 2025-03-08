{ config, lib, pkgs, ... }:

let
  inherit (lib) types;

  cfg = config.xdg.systemDirs;

  configDirs = lib.concatStringsSep ":" cfg.config;

  dataDirs = lib.concatStringsSep ":" cfg.data;

in {
  meta.maintainers = with lib.maintainers; [ tadfisher ];

  options.xdg.systemDirs = {
    config = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = lib.literalExpression ''[ "/etc/xdg" ]'';
      description = ''
        Directory names to add to {env}`XDG_CONFIG_DIRS`
        in the user session.
      '';
    };

    data = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = lib.literalExpression ''[ "/usr/share" "/usr/local/share" ]'';
      description = ''
        Directory names to add to {env}`XDG_DATA_DIRS`
        in the user session.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.config != [ ] || cfg.data != [ ]) {
      assertions = [
        (lib.hm.assertions.assertPlatform "xdg.systemDirs" pkgs
          lib.platforms.linux)
      ];
    })

    (lib.mkIf (cfg.config != [ ]) {
      home.sessionVariables.XDG_CONFIG_DIRS =
        "${configDirs}\${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}";

      systemd.user.sessionVariables.XDG_CONFIG_DIRS =
        "${configDirs}\${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}";
    })

    (lib.mkIf (cfg.data != [ ]) {
      home.sessionVariables.XDG_DATA_DIRS =
        "${dataDirs}\${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}";

      systemd.user.sessionVariables.XDG_DATA_DIRS =
        "${dataDirs}\${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}";
    })
  ];
}
