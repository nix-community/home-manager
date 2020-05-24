{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.fonts.fontconfig;

  profileDirectory = config.home.profileDirectory;

in {
  meta.maintainers = [ maintainers.rycee ];

  imports = [
    (mkRenamedOptionModule [ "fonts" "fontconfig" "enableProfileFonts" ] [
      "fonts"
      "fontconfig"
      "enable"
    ])
  ];

  options = {
    fonts.fontconfig = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable fontconfig configuration. This will, for
          example, allow fontconfig to discover fonts and
          configurations installed through
          <varname>home.packages</varname> and
          <command>nix-env</command>.
        '';
      };
      includes = mkOption {
        type = types.listOf (types.submodule {
          options = {
            ignoreMissing = mkOption {
              type = types.bool;
              default = false;
              description =
                "Ignore this import if the path does not exist. Maps to the `ignore_missing` attribute.";
            };
            path = mkOption {
              type = types.path;
              description = "Path to be included.";
            };
          };
        });
        default = [ ];
        description = "Paths to include.";
      };
      cacheDir = mkOption {
        internal = true;
        type = types.path;
        description = "fontconfig cache directory";
      };
      dirs = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = "Directories to load fonts from.";
      };
    };
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.includes = [
      {
        ignoreMissing = true;
        path = "${config.home.path}/etc/fonts/conf.d";
      }
      {
        ignoreMissing = true;
        path = "${config.home.path}/etc/fonts/fonts.conf";
      }
    ];
    fonts.fontconfig.cacheDir =
      lib.mkDefault "${config.home.path}/lib/fontconfig/cache";
    fonts.fontconfig.dirs = [
      "${config.home.path}/lib/X11/fonts"
      "${config.home.path}/share/fonts"
      "${profileDirectory}/lib/X11/fonts"
      "${profileDirectory}/share/fonts"
    ];

    # Create two dummy files in /lib/fontconfig to make sure that
    # buildEnv creates a real directory path. These files are removed
    # in home.extraProfileCommands below so the packages will not
    # become "runtime" dependencies.
    home.packages = [
      (pkgs.writeTextFile {
        name = "hm-dummy1";
        destination = "/lib/fontconfig/hm-dummy1";
        text = "dummy";
      })

      (pkgs.writeTextFile {
        name = "hm-dummy2";
        destination = "/lib/fontconfig/hm-dummy2";
        text = "dummy";
      })
    ];

    home.extraProfileCommands = ''
      if [[ -d $out/lib/X11/fonts || -d $out/share/fonts ]]; then
        export FONTCONFIG_FILE="$(pwd)/fonts.conf"

        cat > $FONTCONFIG_FILE << EOF
      <?xml version='1.0'?>
      <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
      <fontconfig>
        <dir>$out/lib/X11/fonts</dir>
        <dir>$out/share/fonts</dir>
        <cachedir>$out/lib/fontconfig/cache</cachedir>
      </fontconfig>
      EOF

        ${getBin pkgs.fontconfig}/bin/fc-cache -f
        rm -f $out/lib/fontconfig/cache/CACHEDIR.TAG
        rmdir --ignore-fail-on-non-empty -p $out/lib/fontconfig/cache

        rm "$FONTCONFIG_FILE"
        unset FONTCONFIG_FILE
      fi

      # Remove hacky dummy files.
      rm $out/lib/fontconfig/hm-dummy?
      rmdir --ignore-fail-on-non-empty -p $out/lib/fontconfig
    '';

    xdg.configFile = {
      "fontconfig/conf.d/10-hm-fonts.conf".source = with cfg;
        let
          submoduleToAttrs = m:
            lib.filterAttrs (name: v: name != "_module" && v != null) m;
          mkInclude = { ignoreMissing, path }: {
            name = "include";
            attrs = if ignoreMissing then { ignore_missing = "yes"; } else { };
            content = path;
          };
          mkDir = path: {
            name = "dir";
            content = path;
          };
          includeElements =
            builtins.map (x: mkInclude (submoduleToAttrs x)) includes;
          dirElements = builtins.map mkDir dirs;
          cacheDirElement = {
            name = "cachedir";
            content = cacheDir;
          };
        in lib.hm.xml.genXMLFile {
          doctype = "SYSTEM 'fonts.dtd'";
          root = {
            name = "fontconfig";
            children = includeElements ++ dirElements ++ [ cacheDirElement ];
          };
        };
    };
  };
}
