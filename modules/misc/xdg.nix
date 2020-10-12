{ options, config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xdg;

  dag = config.lib.dag;

  fileType = (import ../lib/file-type.nix {
    inherit (config.home) homeDirectory;
    inherit lib pkgs;
  }).fileType;

  defaultCacheHome = "${config.home.homeDirectory}/.cache";
  defaultConfigHome = "${config.home.homeDirectory}/.config";
  defaultDataHome = "${config.home.homeDirectory}/.local/share";

  getXdgDir = name: fallback:
    let
      value = builtins.getEnv name;
    in
      if value != "" then value else fallback;

in

{
  options.xdg = {
    enable = mkEnableOption "management of XDG base directories";

    cacheHome = mkOption {
      type = types.path;
      defaultText = "~/.cache";
      description = ''
        Absolute path to directory holding application caches.
      '';
    };

    configFile = mkOption {
      type = fileType "<varname>xdg.configHome</varname>" cfg.configHome;
      default = {};
      description = ''
        Attribute set of files to link into the user's XDG
        configuration home.
      '';
    };

    configHome = mkOption {
      type = types.path;
      defaultText = "~/.config";
      description = ''
        Absolute path to directory holding application configurations.
      '';
    };

    dataFile = mkOption {
      type = fileType "<varname>xdg.dataHome</varname>" cfg.dataHome;
      default = {};
      description = ''
        Attribute set of files to link into the user's XDG
        data home.
      '';
    };

    dataHome = mkOption {
      type = types.path;
      defaultText = "~/.local/share";
      description = ''
        Absolute path to directory holding application data.
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      xdg.cacheHome = mkDefault defaultCacheHome;
      xdg.configHome = mkDefault defaultConfigHome;
      xdg.dataHome = mkDefault defaultDataHome;

      home.sessionVariables = {
        XDG_CACHE_HOME = cfg.cacheHome;
        XDG_CONFIG_HOME = cfg.configHome;
        XDG_DATA_HOME = cfg.dataHome;
      };
    })

    # Legacy non-deterministic setup.
    (mkIf (!cfg.enable && versionOlder config.home.stateVersion "20.09") {
      xdg.cacheHome = getXdgDir "XDG_CACHE_HOME" defaultCacheHome;
      xdg.configHome = getXdgDir "XDG_CONFIG_HOME" defaultConfigHome;
      xdg.dataHome = getXdgDir "XDG_DATA_HOME" defaultDataHome;
    })

    # "Modern" deterministic setup.
    (mkIf (!cfg.enable && versionAtLeast config.home.stateVersion "20.09") {
      xdg.cacheHome = mkDefault defaultCacheHome;
      xdg.configHome = mkDefault defaultConfigHome;
      xdg.dataHome = mkDefault defaultDataHome;
    })

    {
      home.file = mkMerge [
        (mapAttrs'
          (name: file: nameValuePair "${config.xdg.configHome}/${name}" file)
          cfg.configFile)
        (mapAttrs'
          (name: file: nameValuePair "${config.xdg.dataHome}/${name}" file)
          cfg.dataFile)
        { "${config.xdg.cacheHome}/.keep".text = ""; }
      ];
    }
  ];
}
