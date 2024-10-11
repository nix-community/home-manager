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

        Sets `XDG_CACHE_HOME` for the user if `xdg.enable` is set `true`.
      '';
    };

    configFile = mkOption {
      type = fileType "xdg.configFile" "{var}`xdg.configHome`" cfg.configHome;
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

        Sets `XDG_CONFIG_HOME` for the user if `xdg.enable` is set `true`.
      '';
    };

    dataFile = mkOption {
      type =
        fileType "xdg.dataFile" "<varname>xdg.dataHome</varname>" cfg.dataHome;
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

        Sets `XDG_DATA_HOME` for the user if `xdg.enable` is set `true`.
      '';
    };

    stateFile = mkOption {
      type = fileType "xdg.stateFile" "<varname>xdg.stateHome</varname>"
        cfg.stateHome;
      default = { };
      description = ''
        Attribute set of files to link into the user's XDG
        state home.
      '';
    };

    stateHome = mkOption {
      type = types.path;
      defaultText = "~/.local/state";
      apply = toString;
      description = ''
        Absolute path to directory holding application states.

        Sets `XDG_STATE_HOME` for the user if `xdg.enable` is set `true`.
      '';
    };
  };

  config = mkMerge [
    (let
      variables = {
        XDG_CACHE_HOME = cfg.cacheHome;
        XDG_CONFIG_HOME = cfg.configHome;
        XDG_DATA_HOME = cfg.dataHome;
        XDG_STATE_HOME = cfg.stateHome;
      };
    in mkIf cfg.enable {
      xdg.cacheHome = mkDefault defaultCacheHome;
      xdg.configHome = mkDefault defaultConfigHome;
      xdg.dataHome = mkDefault defaultDataHome;
      xdg.stateHome = mkDefault defaultStateHome;

      home.sessionVariables = variables;
      systemd.user.sessionVariables =
        mkIf pkgs.stdenv.hostPlatform.isLinux variables;
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
        (mapAttrs' (name: file: nameValuePair "${cfg.stateHome}/${name}" file)
          cfg.stateFile)
        { "${cfg.cacheHome}/.keep".text = ""; }
      ];
    }
  ];
}
