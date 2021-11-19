{ options, config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xdg;

  fileType = (import ../lib/file-type.nix {
    inherit (config.home) homeDirectory;
    inherit lib pkgs;
  }).fileType;

  defaultCacheHome = "${config.home.homeDirectory}/.cache";
  defaultConfigHome = "${config.home.homeDirectory}/.config";
  defaultDataHome = "${config.home.homeDirectory}/.local/share";
  defaultStateHome = "${config.home.homeDirectory}/.local/state";

  getEnvFallback = name: fallback:
    let value = builtins.getEnv name;
    in if value != "" then value else fallback;

in {
  options.xdg = {
    enable = mkEnableOption "management of XDG base directories";

    cacheHome = mkOption {
      type = types.path;
      defaultText = "~/.cache";
      apply = toString;
      description = ''
        Absolute path to directory holding application caches.
      '';
    };

    configFile = mkOption {
      type = fileType "<varname>xdg.configHome</varname>" cfg.configHome;
      default = { };
      description = ''
        Attribute set of files to link into the user's XDG
        configuration home.
      '';
    };

    configHome = mkOption {
      type = types.path;
      defaultText = "~/.config";
      apply = toString;
      description = ''
        Absolute path to directory holding application configurations.
      '';
    };

    dataFile = mkOption {
      type = fileType "<varname>xdg.dataHome</varname>" cfg.dataHome;
      default = { };
      description = ''
        Attribute set of files to link into the user's XDG
        data home.
      '';
    };

    dataHome = mkOption {
      type = types.path;
      defaultText = "~/.local/share";
      apply = toString;
      description = ''
        Absolute path to directory holding application data.
      '';
    };

    stateHome = mkOption {
      type = types.path;
      defaultText = "~/.local/state";
      apply = toString;
      description = ''
        Absolute path to directory holding application states.
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      xdg.cacheHome = mkDefault defaultCacheHome;
      xdg.configHome = mkDefault defaultConfigHome;
      xdg.dataHome = mkDefault defaultDataHome;
      xdg.stateHome = mkDefault defaultStateHome;

      home.sessionVariables = {
        XDG_CACHE_HOME = cfg.cacheHome;
        XDG_CONFIG_HOME = cfg.configHome;
        XDG_DATA_HOME = cfg.dataHome;
        XDG_STATE_HOME = cfg.stateHome;
      };
    })

    # Legacy non-deterministic setup.
    (mkIf (!cfg.enable && versionOlder config.home.stateVersion "20.09") {
      xdg.cacheHome =
        mkDefault (getEnvFallback "XDG_CACHE_HOME" defaultCacheHome);
      xdg.configHome =
        mkDefault (getEnvFallback "XDG_CONFIG_HOME" defaultConfigHome);
      xdg.dataHome = mkDefault (getEnvFallback "XDG_DATA_HOME" defaultDataHome);
    })

    # "Modern" deterministic setup.
    (mkIf (!cfg.enable && versionAtLeast config.home.stateVersion "20.09") {
      xdg.cacheHome = mkDefault defaultCacheHome;
      xdg.configHome = mkDefault defaultConfigHome;
      xdg.dataHome = mkDefault defaultDataHome;
      xdg.stateHome = mkDefault defaultStateHome;
    })

    {
      home.file = mkMerge [
        (mapAttrs' (name: file: nameValuePair "${cfg.configHome}/${name}" file)
          cfg.configFile)
        (mapAttrs' (name: file: nameValuePair "${cfg.dataHome}/${name}" file)
          cfg.dataFile)
        { "${cfg.cacheHome}/.keep".text = ""; }
      ];
    }
  ];
}
