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
    types
    ;

  cfg = config.xdg;

  fileType =
    (import ../lib/file-type.nix {
      inherit (config.home) homeDirectory;
      inherit lib pkgs;
    }).fileType;

  defaultCacheHome = "${config.home.homeDirectory}/.cache";
  defaultConfigHome = "${config.home.homeDirectory}/.config";
  defaultDataHome = "${config.home.homeDirectory}/.local/share";
  defaultStateHome = "${config.home.homeDirectory}/.local/state";

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
      type = fileType "xdg.dataFile" "<varname>xdg.dataHome</varname>" cfg.dataHome;
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
      type = fileType "xdg.stateFile" "<varname>xdg.stateHome</varname>" cfg.stateHome;
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

  config = lib.mkMerge [
    (
      let
        variables = {
          XDG_CACHE_HOME = cfg.cacheHome;
          XDG_CONFIG_HOME = cfg.configHome;
          XDG_DATA_HOME = cfg.dataHome;
          XDG_STATE_HOME = cfg.stateHome;
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
        (lib.mapAttrs' (name: file: lib.nameValuePair "${cfg.cacheHome}/${name}" file) cfg.cacheFile)
        (lib.mapAttrs' (name: file: lib.nameValuePair "${cfg.configHome}/${name}" file) cfg.configFile)
        (lib.mapAttrs' (name: file: lib.nameValuePair "${cfg.dataHome}/${name}" file) cfg.dataFile)
        (lib.mapAttrs' (name: file: lib.nameValuePair "${cfg.stateHome}/${name}" file) cfg.stateFile)
        { "${cfg.cacheHome}/.keep".text = ""; }
        { "${cfg.stateHome}/.keep".text = ""; }
      ];
    }
  ];
}
