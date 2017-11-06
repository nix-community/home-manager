{ options, config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xdg;

  fileType = basePathDesc: basePath: (types.loaOf (types.submodule (
    { name, config, ... }: {
      options = {
        target = mkOption {
          type = types.str;
          apply = p: "${basePath}/${p}";
          description = ''
            Path to target file relative to <varname>${basePathDesc}</varname>.
          '';
        };

        text = mkOption {
          default = null;
          type = types.nullOr types.lines;
          description = "Text of the file.";
        };

        source = mkOption {
          type = types.path;
          description = ''
            Path of the source file. The file name must not start
            with a period since Nix will not allow such names in
            the Nix store.
            </para><para>
            This may refer to a directory.
          '';
        };

        executable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether the file should be executable.";
        };
      };

      config = {
        target = mkDefault name;
        source = mkIf (config.text != null) (
          let
            file = pkgs.writeTextFile {
              inherit (config) text executable;
              name = "user-etc-" + baseNameOf name;
            };
          in
            mkDefault file
        );
      };
    }
  )));

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
      type = fileType "xdg.configHome" cfg.configHome;
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

    (mkIf (!cfg.enable) {
      xdg.cacheHome = getXdgDir "XDG_CACHE_HOME" defaultCacheHome;
      xdg.configHome = getXdgDir "XDG_CONFIG_HOME" defaultConfigHome;
      xdg.dataHome = getXdgDir "XDG_DATA_HOME" defaultDataHome;
    })

    {
      home.file = cfg.configFile;
    }
  ];
}
