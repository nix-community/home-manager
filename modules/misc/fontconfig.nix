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
    };
  };

  config = mkIf cfg.enable {
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
      "fontconfig/conf.d/10-hm-fonts.conf".source = let
        mkInclude = { ignore ? false, path }: {
          name = "include";
          attrs = if ignore then { ignore_missing = "yes"; } else { };
          content = path;
        };
        mkDir = path: {
          name = "dir";
          content = path;
        };
        includes = [
          {
            ignore = true;
            path = "${config.home.path}/etc/fonts/conf.d";
          }
          {
            ignore = true;
            path = "${config.home.path}/etc/fonts/fonts.conf";
          }
        ];
        includeElements = builtins.map mkInclude includes;
        dirs = [
          "${profileDirectory}/lib/X11/fonts"
          "${profileDirectory}/share/fonts"
          "${profileDirectory}/lib/X11/fonts"
          "${profileDirectory}/share/fonts"
        ];
        dirElements = builtins.map mkDir dirs;
        cacheDir = "${config.home.path}/lib/fontconfig/cache";
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
