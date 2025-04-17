{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOptionDefault
    mkIf
    mkOption
    ;

  cfg = config.xdg;

  fileType =
    (import ../lib/file-type.nix {
      inherit (config.lib) homePath;
      inherit lib pkgs;
    }).fileType;

  defaultCacheHome = "~/.cache";
  defaultConfigHome = "~/.config";
  defaultDataHome = "~/.local/share";
  defaultStateHome = "~/.local/state";

  getEnvFallback =
    name: fallback:
    let
      value = builtins.getEnv name;
    in
    if value != "" then value else fallback;

in
{
  options.xdg = {
    enable = lib.mkEnableOption "management of XDG base directories";

    cacheFile = mkOption {
      type = fileType "xdg.cacheFile" "{var}`xdg.cacheHome`" cfg.cacheHome;
      default = { };
      description = ''
        Attribute set of files to link into the user's XDG
        cache home.
      '';
    };

    cacheHome = mkOption {
      type = config.lib.homePath.type;
      defaultText = defaultCacheHome;
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
      type = config.lib.homePath.type;
      defaultText = defaultConfigHome;
      description = ''
        Absolute path to directory holding application configurations.

        Sets `XDG_CONFIG_HOME` for the user if `xdg.enable` is set `true`.
      '';
    };

    dataFile = mkOption {
      type = fileType "xdg.dataFile" "<varname>xdg.dataHome</varname>" cfg.dataHome;
      default = { };
      description = ''
        Attribute set of files to link into the user's XDG
        data home.
      '';
    };

    dataHome = mkOption {
      type = config.lib.homePath.type;
      defaultText = defaultDataHome;
      description = ''
        Absolute path to directory holding application data.

        Sets `XDG_DATA_HOME` for the user if `xdg.enable` is set `true`.
      '';
    };

    stateFile = mkOption {
      type = fileType "xdg.stateFile" "<varname>xdg.stateHome</varname>" cfg.stateHome;
      default = { };
      description = ''
        Attribute set of files to link into the user's XDG
        state home.
      '';
    };

    stateHome = mkOption {
      type = config.lib.homePath.type;
      defaultText = defaultStateHome;
      description = ''
        Absolute path to directory holding application states.

        Sets `XDG_STATE_HOME` for the user if `xdg.enable` is set `true`.
      '';
    };
  };

  config = lib.mkMerge [
    (
      let
        variables = {
          XDG_CACHE_HOME = cfg.cacheHome.environment;
          XDG_CONFIG_HOME = cfg.configHome.environment;
          XDG_DATA_HOME = cfg.dataHome.environment;
          XDG_STATE_HOME = cfg.stateHome.environment;
        };
      in
      mkIf cfg.enable {
        xdg.cacheHome = mkOptionDefault defaultCacheHome;
        xdg.configHome = mkOptionDefault defaultConfigHome;
        xdg.dataHome = mkOptionDefault defaultDataHome;
        xdg.stateHome = mkOptionDefault defaultStateHome;

        home.sessionVariables = variables;
        systemd.user.sessionVariables = mkIf pkgs.stdenv.hostPlatform.isLinux variables;
      }
    )

    # Legacy non-deterministic setup.
    (mkIf (!cfg.enable && lib.versionOlder config.home.stateVersion "20.09") {
      xdg.cacheHome = mkOptionDefault (getEnvFallback "XDG_CACHE_HOME" defaultCacheHome);
      xdg.configHome = mkOptionDefault (getEnvFallback "XDG_CONFIG_HOME" defaultConfigHome);
      xdg.dataHome = mkOptionDefault (getEnvFallback "XDG_DATA_HOME" defaultDataHome);
      xdg.stateHome = mkOptionDefault (getEnvFallback "XDG_STATE_HOME" defaultStateHome);
    })

    # "Modern" deterministic setup.
    (mkIf (!cfg.enable && lib.versionAtLeast config.home.stateVersion "20.09") {
      xdg.cacheHome = mkOptionDefault defaultCacheHome;
      xdg.configHome = mkOptionDefault defaultConfigHome;
      xdg.dataHome = mkOptionDefault defaultDataHome;
      xdg.stateHome = mkOptionDefault defaultStateHome;
    })

    {
      home.file = lib.mkMerge [
        (lib.mapAttrs' (
          name: file: lib.nameValuePair "${cfg.cacheHome.relative}/${name}" file
        ) cfg.cacheFile)
        (lib.mapAttrs' (
          name: file: lib.nameValuePair "${cfg.configHome.relative}/${name}" file
        ) cfg.configFile)
        (lib.mapAttrs' (name: file: lib.nameValuePair "${cfg.dataHome.relative}/${name}" file) cfg.dataFile)
        (lib.mapAttrs' (
          name: file: lib.nameValuePair "${cfg.stateHome.relative}/${name}" file
        ) cfg.stateFile)
        { "${cfg.cacheHome.relative}/.keep".text = ""; }
        { "${cfg.stateHome.relative}/.keep".text = ""; }
      ];
    }
  ];
}
