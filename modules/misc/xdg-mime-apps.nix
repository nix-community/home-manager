{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;

  cfg = config.xdg.mimeApps;

  strListOrSingleton = with types; coercedTo (either (listOf str) str) lib.toList (listOf str);

in
{
  meta.maintainers = with lib.maintainers; [ euxane ];

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
      example = lib.literalExpression ''
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
      example = {
        "mimetype1" = "foo5.desktop";
      };
      description = ''
        Removes associations of applications with mimetypes, as if the
        .desktop file was *not* listing this
        mimetype in the first place.
      '';
    };

    defaultApplications = mkOption {
      type = types.attrsOf strListOrSingleton;
      default = { };
      example = lib.literalExpression ''
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

    defaultApplicationPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = [
        pkgs.eog
        pkgs.evince
      ];
      description = ''
        Packages whose `.desktop` files will be used to establish default
        mimetype associations.

        These associations are appended to the associations in
        [](#opt-xdg.mimeApps.defaultApplications). If multiple packages
        associate with the same mime type, then the priority among them is
        determined by their order in the list.
      '';
    };
  };

  config = lib.mkMerge [
    {
      # Given a package that installs .desktop files in the usual location,
      # return a mapping from mime types to lists of desktop file names. This is
      # suitable for use with `xdg.mimeApps.defaultApplications`.
      lib.xdg.mimeAssociations =
        let
          processLines =
            str: lib.zipAttrs (lib.filter (e: e != null) (map processLine (lib.splitString "\n" str)));

          processLine =
            str:
            let
              entry = lib.splitString ";" str;
              k = lib.elemAt entry 0;
              v = lib.elemAt entry 1;
            in
            if lib.length entry == 2 then { ${k} = v; } else null;

          associations =
            ps:
            pkgs.runCommand "mime-assoc" { inherit ps; } ''
              for p in $ps ; do
                for path in "$p"/share/applications/*.desktop ; do
                  name="''${path##*/}"
                  sed -n -E "/^MimeType=/ { s/.*=//; s/;?$|;/;$name\n/g; p; }" "$path"
                done
              done > "$out"
            '';

          processAll = p: processLines (builtins.readFile (associations p));

          warning = "The Home Manager `lib.xdg.mimeAssociations` function is deprecated, you can now instead use the option `xdg.mimeApps.defaultApplicationPackages` to achieve the same without import from derivation";
        in
        lib.warn warning processAll;
    }

    (lib.mkIf cfg.enable {
      assertions = [
        (lib.hm.assertions.assertPlatform "xdg.mimeApps" pkgs lib.platforms.linux)
      ];

      # Deprecated but still used by some applications.
      xdg.dataFile."applications/mimeapps.list".source = config.xdg.configFile."mimeapps.list".source;

      xdg.configFile."mimeapps.list".source =
        let
          joinValues = lib.mapAttrs (_n: lib.concatStringsSep ";");

          baseFile = (pkgs.formats.ini { }).generate "mimeapps.list" {
            "Added Associations" = joinValues cfg.associations.added;
            "Removed Associations" = joinValues cfg.associations.removed;
            "Default Applications" = joinValues cfg.defaultApplications;
          };

          # With default application packages merged into the generated base file.
          mergedFile = pkgs.runCommand "mimeapps.list" { ps = cfg.defaultApplicationPackages; } ''
            export PATH=$PATH:${pkgs.crudini}/bin

            function mergeEntry() {
              local mime="$1"
              local name="$2"
              local existing

              existing="$(crudini --get $out 'Default Applications' "$mime" 2>/dev/null || true)"
              local value="$existing''${existing:+;}''$name"
              crudini --ini-options=nospace --inplace --set $out 'Default Applications' "$mime" "$value"
            }

            install -m644 ${baseFile} $out

            for p in $ps ; do
              for path in "$p"/share/applications/*.desktop ; do
                name="''${path##*/}"
                mimes=$(crudini --get "$path" 'Desktop Entry' MimeType 2>/dev/null || true)
                for mime in ''${mimes//;/ }; do
                  mergeEntry "$mime" "$name"
                done
              done
            done
          '';
        in
        if cfg.defaultApplicationPackages == [ ] then baseFile else mergedFile;
    })
  ];
}
