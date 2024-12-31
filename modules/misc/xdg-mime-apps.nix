{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xdg.mimeApps;

  strListOrSingleton = with types;
    coercedTo (either (listOf str) str) toList (listOf str);

in {
  meta.maintainers = with maintainers; [ euxane ];

  options.xdg.mimeApps = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to manage {file}`$XDG_CONFIG_HOME/mimeapps.list`.

        The generated file is read-only.
      '';
    };

    # descriptions from
    # https://specifications.freedesktop.org/mime-apps-spec/mime-apps-spec-1.0.1.html

    associations.added = mkOption {
      type = types.attrsOf strListOrSingleton;
      default = { };
      example = literalExpression ''
        {
          "mimetype1" = [ "foo1.desktop" "foo2.desktop" "foo3.desktop" ];
          "mimetype2" = "foo4.desktop";
        }
      '';
      description = ''
        Defines additional associations of applications with
        mimetypes, as if the .desktop file was listing this mimetype
        in the first place.
      '';
    };

    associations.removed = mkOption {
      type = types.attrsOf strListOrSingleton;
      default = { };
      example = { "mimetype1" = "foo5.desktop"; };
      description = ''
        Removes associations of applications with mimetypes, as if the
        .desktop file was *not* listing this
        mimetype in the first place.
      '';
    };

    defaultApplications = mkOption {
      type = types.attrsOf strListOrSingleton;
      default = { };
      example = literalExpression ''
        {
          "mimetype1" = [ "default1.desktop" "default2.desktop" ];
        }
      '';
      description = ''
        The default application to be used for a given mimetype. This
        is, for instance, the one that will be started when
        double-clicking on a file in a file manager. If the
        application is no longer installed, the next application in
        the list is attempted, and so on.
      '';
    };
  };

  config = mkMerge [
    {
      # Given a package that installs .desktop files in the usual location,
      # return a mapping from mime types to lists of desktop file names. This is
      # suitable for use with `xdg.mimeApps.defaultApplications`.
      lib.xdg.mimeAssociations = let
        processLines = str:
          zipAttrs
          (filter (e: e != null) (map processLine (splitString "\n" str)));

        processLine = str:
          let
            entry = splitString ";" str;
            k = elemAt entry 0;
            v = elemAt entry 1;
          in if length entry == 2 then { ${k} = v; } else null;

        associations = ps:
          pkgs.runCommand "mime-assoc" { inherit ps; } ''
            for p in $ps ; do
              for path in "$p"/share/applications/*.desktop ; do
                name="''${path##*/}"
                sed -n -E "/^MimeType=/ { s/.*=//; s/;?$|;/;$name\n/g; p; }" "$path"
              done
            done > "$out"
          '';
      in p: processLines (builtins.readFile (associations p));
    }

    (mkIf cfg.enable {
      assertions =
        [ (hm.assertions.assertPlatform "xdg.mimeApps" pkgs platforms.linux) ];

      # Deprecated but still used by some applications.
      xdg.dataFile."applications/mimeapps.list".source =
        config.xdg.configFile."mimeapps.list".source;

      xdg.configFile."mimeapps.list".text =
        let joinValues = mapAttrs (n: concatStringsSep ";");
        in generators.toINI { } {
          "Added Associations" = joinValues cfg.associations.added;
          "Removed Associations" = joinValues cfg.associations.removed;
          "Default Applications" = joinValues cfg.defaultApplications;
        };
    })
  ];
}
