{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xdg.mimeApps;

  strListOrSingleton = with types;
    coercedTo (either (listOf str) str) toList (listOf str);

in

{
  meta.maintainers = with maintainers; [ pacien ];

  options.xdg.mimeApps = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to manage <filename>$XDG_CONFIG_HOME/mimeapps.list</filename>.
        </para>
        <para>
        The generated file is read-only.
      '';
    };

    # descriptions from
    # https://specifications.freedesktop.org/mime-apps-spec/mime-apps-spec-1.0.1.html

    associations.added = mkOption {
      type = types.attrsOf strListOrSingleton;
      default = { };
      example = literalExample ''
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
        .desktop file was <emphasis>not</emphasis> listing this
        mimetype in the first place.
      '';
    };

    defaultApplications = mkOption {
      type = types.attrsOf strListOrSingleton;
      default = { };
      example = literalExample ''
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

  config = mkIf cfg.enable {
    # Deprecated but still used by some applications.
    home.file.".local/share/applications/mimeapps.list".source =
      config.xdg.configFile."mimeapps.list".source;

    xdg.configFile."mimeapps.list".text =
      let
        joinValues = mapAttrs (n: concatStringsSep ";");
      in
        generators.toINI {} {
          "Added Associations" = joinValues cfg.associations.added;
          "Removed Associations" = joinValues cfg.associations.removed;
          "Default Applications" = joinValues cfg.defaultApplications;
        };
  };
}
