{ config, lib, pkgs, ... }:

with lib;

let
  desktopEntry = {
    imports = [
      (mkRemovedOptionModule [ "extraConfig" ]
        "The `extraConfig` option of `xdg.desktopEntries` has been removed following a change in Nixpkgs.")
      (mkRemovedOptionModule [ "fileValidation" ]
        "Validation of the desktop file is always enabled.")
    ];
    options = {
      # Since this module uses the nixpkgs/pkgs/build-support/make-desktopitem function,
      # our options and defaults follow its parameters, with the following exceptions:

      # `desktopName` on makeDesktopItem is controlled by `name`.
      # This is what we'd commonly consider the name of the application.
      # `name` on makeDesktopItem is controlled by this module's key in the attrset.
      # This is the file's filename excluding ".desktop".

      # `extraConfig` on makeDesktopItem is controlled by `settings`,
      # to match what's commonly used by other home manager modules.

      # Descriptions are taken from the desktop entry spec:
      # https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#recognized-keys

      type = mkOption {
        description = "The type of the desktop entry.";
        default = "Application";
        type = types.enum [ "Application" "Link" "Directory" ];
      };

      exec = mkOption {
        description = "Program to execute, possibly with arguments.";
        type = types.nullOr types.str;
        default = null;
      };

      icon = mkOption {
        description = "Icon to display in file manager, menus, etc.";
        type = with types; nullOr (either str path);
        default = null;
      };

      comment = mkOption {
        description = "Tooltip for the entry.";
        type = types.nullOr types.str;
        default = null;
      };

      terminal = mkOption {
        description = "Whether the program runs in a terminal window.";
        type = types.bool;
        default = false;
      };

      name = mkOption {
        description = "Specific name of the application.";
        type = types.str;
      };

      genericName = mkOption {
        description = "Generic name of the application.";
        type = types.nullOr types.str;
        default = null;
      };

      mimeType = mkOption {
        description = "The MIME type(s) supported by this application.";
        type = types.nullOr (types.listOf types.str);
        default = null;
      };

      categories = mkOption {
        description =
          "Categories in which the entry should be shown in a menu.";
        type = types.nullOr (types.listOf types.str);
        default = null;
      };

      startupNotify = mkOption {
        description = ''
          If true, it is KNOWN that the application will send a "remove"
          message when started with the <literal>DESKTOP_STARTUP_ID</literal>
          environment variable set. If false, it is KNOWN that the application
          does not work with startup notification at all.'';
        type = types.nullOr types.bool;
        default = null;
      };

      noDisplay = mkOption {
        description = ''
          Means "this application exists, but don't display it in the menus".
          This can be useful to e.g. associate this application with MIME types.
        '';
        type = types.nullOr types.bool;
        default = null;
      };

      prefersNonDefaultGPU = mkOption {
        description = ''
          If true, the application prefers to be run on a more powerful discrete GPU if available.
        '';
        type = types.nullOr types.bool;
        default = null;
      };

      settings = mkOption {
        type = types.attrsOf types.string;
        description = ''
          Extra key-value pairs to add to the <literal>[Desktop Entry]</literal> section.
          This may override other values.
        '';
        default = { };
        example = literalExpression ''
          {
            Keywords = "calc;math";
            DBusActivatable = "false";
          }
        '';
      };

      actions = mkOption {
        type = types.attrsOf (types.submodule ({ name, ... }: {
          options.name = mkOption {
            type = types.str;
            default = name;
            defaultText = literalExpression "<name>";
            description = "Name of the action.";
          };
          options.exec = mkOption {
            type = types.nullOr types.str;
            description = "Program to execute, possibly with arguments.";
            default = null;
          };
          options.icon = mkOption {
            type = with types; nullOr (either str path);
            default = null;
            description = "Icon to display in file manager, menus, etc.";
          };
        }));
        default = { };
        defaultText = literalExpression "{ }";
        example = literalExpression ''
          {
            "New Window" = {
              exec = "''${pkgs.firefox}/bin/firefox --new-window %u";
            };
          }
        '';
        description =
          "The set of actions made available to application launchers.";
      };

      # Required for the assertions
      # TODO: Remove me once https://github.com/NixOS/nixpkgs/issues/96006 is fixed
      assertions = mkOption {
        type = types.listOf types.unspecified;
        default = [ ];
        visible = false;
        internal = true;
      };
    };
  };

  #passes config options to makeDesktopItem in expected format
  makeFile = name: config:
    pkgs.makeDesktopItem {
      inherit name;
      inherit (config)
        type exec icon comment terminal genericName startupNotify noDisplay
        prefersNonDefaultGPU actions;
      desktopName = config.name;
      mimeTypes = optionals (config.mimeType != null) config.mimeType;
      categories = optionals (config.categories != null) config.categories;
      extraConfig = config.settings;
    };
in {
  meta.maintainers = [ hm.maintainers.cwyc ];

  options.xdg.desktopEntries = mkOption {
    description = ''
      Desktop Entries allow applications to be shown in your desktop environment's app launcher. </para><para>
      You can define entries for programs without entries or override existing entries. </para><para>
      See <link xlink:href="https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#recognized-keys" /> for more information on options.
    '';
    default = { };
    type = types.attrsOf (types.submodule desktopEntry);
    example = literalExpression ''
      {
        firefox = {
          name = "Firefox";
          genericName = "Web Browser";
          exec = "firefox %U";
          terminal = false;
          categories = [ "Application" "Network" "WebBrowser" ];
          mimeType = [ "text/html" "text/xml" ];
        };
      }
    '';
  };

  config = mkIf (config.xdg.desktopEntries != { }) {
    assertions = [
      (hm.assertions.assertPlatform "xdg.desktopEntries" pkgs platforms.linux)
    ] ++ flatten (catAttrs "assertions" (attrValues config.xdg.desktopEntries));

    home.packages = (map hiPrio # we need hiPrio to override existing entries
      (attrsets.mapAttrsToList makeFile config.xdg.desktopEntries));
  };

}
