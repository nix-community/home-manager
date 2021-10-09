{ config, lib, pkgs, ... }:

with lib;

let
  desktopEntry = {
    options = {
      # Since this module uses the nixpkgs/pkgs/build-support/make-desktopitem function, 
      # our options and defaults follow its parameters, with the following exceptions:

      # `desktopName` on makeDesktopItem is controlled by `name`.
      # This is what we'd commonly consider the name of the application.
      # `name` on makeDesktopItem is controlled by this module's key in the attrset.
      # This is the file's filename excluding ".desktop".

      # `extraEntries` on makeDesktopItem is controlled by `extraConfig`,
      # and `extraDesktopEntries` by `settings`,
      # to match what's commonly used by other home manager modules.

      # `startupNotify` on makeDesktopItem asks for "true" or "false" strings,
      # for usability's sake we ask for a boolean.

      # `mimeType` and `categories` on makeDesktopItem ask for a string in the format "one;two;three;",
      # for the same reason we ask for a list of strings.

      # Descriptions are taken from the desktop entry spec: 
      # https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#recognized-keys

      type = mkOption {
        description = "The type of the desktop entry.";
        default = "Application";
        type = types.enum [ "Application" "Link" "Directory" ];
      };

      exec = mkOption {
        description = "Program to execute, possibly with arguments.";
        type = types.str;
      };

      icon = mkOption {
        description = "Icon to display in file manager, menus, etc.";
        type = types.nullOr types.str;
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

      extraConfig = mkOption {
        description = ''
          Extra configuration. Will be appended to the end of the file and 
          may thus contain extra sections.
        '';
        type = types.lines;
        default = "";
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

      fileValidation = mkOption {
        type = types.bool;
        description = "Whether to validate the generated desktop file.";
        default = true;
      };
    };
  };

  #formatting helpers
  ifNotNull = a: a': if a == null then null else a';
  stringBool = bool: if bool then "true" else "false";
  semicolonList = list:
    (concatStringsSep ";" list) + ";"; # requires trailing semicolon

  #passes config options to makeDesktopItem in expected format
  makeFile = name: config:
    pkgs.makeDesktopItem {
      name = name;
      type = config.type;
      exec = config.exec;
      icon = config.icon;
      comment = config.comment;
      terminal = config.terminal;
      desktopName = config.name;
      genericName = config.genericName;
      mimeType = ifNotNull config.mimeType (semicolonList config.mimeType);
      categories =
        ifNotNull config.categories (semicolonList config.categories);
      startupNotify =
        ifNotNull config.startupNotify (stringBool config.startupNotify);
      extraEntries = config.extraConfig;
      extraDesktopEntries = config.settings;
    };
in {
  meta.maintainers = with maintainers; [ cwyc ];

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
    ];

    home.packages = (map hiPrio # we need hiPrio to override existing entries
      (attrsets.mapAttrsToList makeFile config.xdg.desktopEntries));
  };

}
