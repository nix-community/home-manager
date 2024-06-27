{ config, lib, pkgs, ... }:

let
  cfg = config.programs.joplin-desktop;

  jsonFormat = pkgs.formats.json { };

  # config path is the same for linux and mac
  configPath = "${config.xdg.configHome}/joplin-desktop";

  # toJoplinSettings receives cfg as input and creates the content of the joplin-desktop/settings.json file
  toJoplinSettings = settings:
    (jsonFormat.generate "joplin-settings.json"
      (lib.attrsets.filterAttrsRecursive (n: v: v != null) ({
        ### General
        "editor" = settings.general.editor;
        "locale" = settings.general.language;
        ### Sync
        "sync.interval" = {
          "" = null;
          "disabled" = 0;
          "5m" = 300;
          "10m" = 600;
          "30m" = 1800;
          "1h" = 3600;
          "12h" = 43200;
          "1d" = 86400;
        }.${settings.sync.interval};
        ### Appearance
        "theme" = {
          "" = null;
          "light" = 1;
          "dark" = 2;
          "solarised-light" = 3;
          "solarised-dark" = 4;
          "dracula" = 5;
          "nord" = 6;
          "aritim-dark" = 7;
          "oled-dark" = 22;
        }.${settings.appearance.theme};
        "themeAutoDetect" = settings.appearance.autoDetectTheme;
        ### Note
        "imageResizing" = settings.note.resizeLargeImages;
        "newTodoFocus" = settings.note.newTodoFocus;
        "newNoteFocus" = settings.note.newTodoFocus;
        "trackLocation" = settings.note.saveGeoLocation;
        "editor.autoMatchingBraces" = settings.note.autoPairBraces;
      }
      ### Markdown
      # map all values; replaces "markdown.plugin.softbreaks" = settings.markdown.softbreaks;
        // (lib.attrsets.concatMapAttrs
          (name: value: { "markdown.plugin.${name}" = value; })
          settings.markdown)
        ### Application
        ### Encryption
        ### Web Clipper
        ### Keyboard Shortcuts
        // settings.extraConfig)));

  # This creates the content of the joplin-desktop/<profile-name>/settings.json file
  toProfileSettings = settings:
    (jsonFormat.generate "profile-settings.json"
      (lib.attrsets.filterAttrsRecursive (n: v: v != null) {
        ### Sync
        "sync.target" = {
          "" = null;
          "none" = 0;
          "file-system" = 2;
          "onedrive" = 3;
          "nextcloud" = 5;
          "webdav" = 6;
          "dropbox" = 7;
          "s3" = 8;
          "joplin-server" = 9;
          "joplin-cloud" = 10;
        }.${settings.sync.target};
        ### Note History
        "revisionService.enabled" = settings.noteHistory.enable;
        "revisionService.ttlDays" = settings.noteHistory.historyDuration;
      } // settings.extraConfig));

  # This creates the content of the joplin-desktop/profiles.json file
  toJoplinProfiles = profiles:
    (jsonFormat.generate "profiles.json" ({
      "profiles" = (builtins.map (name: {
        "name" = name;
        "id" = profiles.${name}.id;
      }) (builtins.attrNames profiles));
    }));

in {
  meta.maintainers = [ lib.hm.maintainers.zorrobert ];

  options.programs.joplin-desktop = {
    enable = lib.mkEnableOption "joplin-desktop";

    package = lib.mkPackageOption pkgs "joplin-desktop" { };

    # This could be implemented in the future if needed
    # useNixStore = lib.mkOption {
    #   type = lib.types.bool;
    #   default = false;
    #   description = ''
    #     There are two ways to configure Joplin, #1 is the default:
    #     #1: Use jq and printf to generate and write to .config/joplin-desktop/settings.json.
    #     #2: Use home.file to create the config file in the Nix Store and link it to .config/joplin-desktop/settings.json.
    #
    #     Both methods have advantages and drawbacks:
    #     #1: This method still allows the user to change settings via the Joplin GUI, which is good for usability. This is also necessary to find out what to put into the extraConfig option to change a  setting not covered by this module. The problem is that the file is only written when options in home-manager are changed, but not when changes are made via the GUI, potentially leading to inconsistencies across systems.
    #     #2: Because the Nix Store is read-only, settings can't be changed via the Joplin GUI. The advantage is that this ensures that every system has the same config file because it is only written by home-manager. The problem is that since Joplin itself can't modify the config file, it can't store things like "api.token", "$schema" or "ui.layout", which could break things.
    #
    #     Because of the potentially side effects that a read-only config file could have on Joplin, #1 is the default. Still, there may be cases where #2 could be useful.
    #   '';
    # };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      example = {
        "newNoteFocus" = "title";
        "markdown.plugin.mark" = true;
        "sync.interval" = 600;
      };
      description = ''
        Use this to add other options to the global Joplin config file. Settings are
        written in JSON, so `"sync.interval": 600` would be written as
        `"sync.interval" = 600;`.
      '';
    };

    ### General
    general = {
      editor = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "kate";
        description = ''
          The editor command (may include arguments) that will be used to open a
          note. If none is provided Joplin will try to auto-detect the default
          editor.
        '';
      };

      language = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "en_GB";
        description = "The language of the Joplin Application.";
      };
    };

    ### Sync
    sync = {
      interval = lib.mkOption {
        type =
          lib.types.enum [ "" "disabled" "5m" "10m" "30m" "1h" "12h" "1d" ];
        default = "";
        example = "10m";
        description = "Set the synchronisation interval.";
      };
    };

    ### Appearance
    appearance = {
      theme = lib.mkOption {
        type = lib.types.enum [
          ""
          "light"
          "dark"
          "solarised-light"
          "solarised-dark"
          "dracula"
          "nord"
          "aritim-dark"
          "oled-dark"
        ];
        default = "";
        example = "10m";
        description = "Set the application theme.";
      };

      autoDetectTheme = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Automatically switch theme to match system theme.";
      };
    };

    ### Note
    note = {
      resizeLargeImages = lib.mkOption {
        type = lib.types.enum [ null "alwaysResize" "alwaysAsk" "neverResize" ];
        default = null;
        description =
          "Shrink large images before adding them to notes to save storage space.";
      };

      newTodoFocus = lib.mkOption {
        type = lib.types.enum [ null "body" "title" ];
        default = null;
        description = "Focus body or title when creating a new to-do.";
      };

      newNoteFocus = lib.mkOption {
        type = lib.types.enum [ null "body" "title" ];
        default = null;
        description = "Focus body or title when creating a new note.";
      };

      saveGeoLocation = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Whether to save geo-location to the note.";
      };

      autoPairBraces = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description =
          "Whether to auto-pair braces, paranthesis, quotations, etc.";
      };
    };

    ### Plugins (WIP)
    # This is a WIP and not ready for release yet
    #plugins = {
    #  installedPlugins = lib.mkOption {
    #    type = lib.types.listOf lib.types.str;
    #    default = [ ];
    #    example = [
    #      "com.s73ph4n.automate_notes"
    #      "com.github.marc0l92.joplin-plugin-drawio"
    #      "com.gitlab.BeatLink.joplin-plugin-agenda"
    #    ];
    #    description = ''
    #      A list of plugins to install.
    #      The full list of Plugins can be found here:
    #      https://github.com/joplin/plugins/blob/master/README.md#plugins
    #      The plugin name can be found in the download URL:
    #      https://github.com/joplin/plugins/raw/master/plugins/PLUGIN-NAME/plugin.jpl
    #    '';
    #  };
    #};

    ### Markdown
    # The markdown options are all booleans with default = null, the definitions can be shortened.
    markdown = let
      type = lib.types.nullOr lib.types.bool;
      default = null;
    in {
      softbreaks = lib.mkOption {
        inherit type default;
        description = "Enable soft breaks (wysiwyg: yes)";
      };
      typographer = lib.mkOption {
        inherit type default;
        description = "Enable typographer support (wysiwyg: yes)";
      };
      linkify = lib.mkOption {
        inherit type default;
        description = "Enable Linkify (wysiwyg: yes)";
      };
      math = lib.mkOption {
        inherit type default;
        description = "Enable math expressions (wysiwyg: yes)";
      };
      fountain = lib.mkOption {
        inherit type default;
        description = "Enable Fountain support (wysiwyg: yes)";
      };
      mermaid = lib.mkOption {
        inherit type default;
        description = "Enable Mermaid diagrams support (wysiwyg: yes)";
      };
      audioPlayer = lib.mkOption {
        inherit type default;
        description = "Enable audio player (wysiwyg: no)";
      };
      videoPlayer = lib.mkOption {
        inherit type default;
        description = "Enable video player (wysiwyg: no)";
      };
      pdfViewer = lib.mkOption {
        inherit type default;
        description = "Enable PDF viewer (wysiwyg: no)";
      };
      mark = lib.mkOption {
        inherit type default;
        description = "Enable ==mark== syntax (wysiwyg: yes)";
      };
      footnote = lib.mkOption {
        inherit type default;
        description = "Enable footnotes (wysiwyg: no)";
      };
      toc = lib.mkOption {
        inherit type default;
        description = "Enable table of contents extension (wysiwyg: no)";
      };
      sub = lib.mkOption {
        inherit type default;
        description = "Enable ~sub~ syntax (wysiwyg: yes)";
      };
      sup = lib.mkOption {
        inherit type default;
        description = "Enable ^sup^ syntax (wysiwyg: yes)";
      };
      deflist = lib.mkOption {
        inherit type default;
        description = "Enable deflist syntax (wysiwyg: no)";
      };
      abbr = lib.mkOption {
        inherit type default;
        description = "Enable abbreviation syntax (wysiwyg: no)";
      };
      emoji = lib.mkOption {
        inherit type default;
        description = "Enable markdown emoji (wysiwyg: no)";
      };
      insert = lib.mkOption {
        inherit type default;
        description = "Enable ++insert++ syntax (wysiwyg: yes)";
      };
      multitable = lib.mkOption {
        inherit type default;
        description = "Enable multimarkdown table extension (wysiwyg: no)";
      };
    };

    ### Application
    ### Encryption
    ### Web Clipper
    ### Keyboard Shortcuts

    profiles = lib.mkOption {
      default = { };
      description = ''
        Joplin supports creating multiple profiles. The settings in this set
        are profile-specific, while others are shared between profiles.
        See https://joplinapp.org/help/apps/profiles/
      '';
      type = lib.types.attrsOf (lib.types.submodule ({ config, name, ... }: {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Profile name.";
          };

          id = lib.mkOption {
            type = lib.types.str;
            # The default profile has the name "Default" and needs the ID "default".
            default = (if name == "Default" then
              "default"
            else
              (builtins.substring 0 8 (builtins.hashString "md5" name)));
            description = ''
              The Profile ID.
              This should be unique string of 8 characters per profile.
              By default, the first 8 characters of the md5  hash
              of the profile name are used.
            '';
          };

          extraConfig = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            example = {
              "newNoteFocus" = "title";
              "markdown.plugin.mark" = true;
            };
            description = ''
              Use this to further modify the config file of this profile.
              Settings are written in JSON, so `"sync.target": 7` would be
              written as `"sync.target" = "dropbox";`.
              Note that if you add settings here that Joplin views as
              "global settings" (see https://joplinapp.org/help/apps/profiles/),
              they will not be applied in the profile.
              Try to use the joplin-desktop.extraConfig option instead.
            '';
          };

          ### Sync
          sync = {
            target = lib.mkOption {
              type = lib.types.enum [
                ""
                "none"
                "file-system"
                "onedrive"
                "nextcloud"
                "webdav"
                "dropbox"
                "s3"
                "joplin-server"
                "joplin-cloud"
              ];
              default = "";
              example = "dropbox";
              description = "What is the type of sync target.";
            };
          };

          ### Note History (profile-specific)
          noteHistory = {
            enable = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              description = "Enable note history.";
            };
            historyDuration = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "Keep Note History for (days)";
            };
          };
        };
      }));
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = (lib.attrsets.matchAttrs { Default = { id = "default"; }; }
        cfg.profiles);
      message = ''
        Joplin-Desktop: The profile 'Default' must exist and have an ID other than 'default'.
      '';
    }];

    home.packages = [ cfg.package ];

    home.activation = {
      createJoplinConfig = lib.hm.dag.entryAfter [ "linkGeneration" ]
        (lib.concatStringsSep "\n" (
          # write the global config file (including settings for the default profile)
          [''
            # Ensure that settings.json exists.
            mkdir -p ${configPath}
            touch ${configPath}/settings.json
            # Config has to be written to temporary variable because jq cannot edit files in place.
            config="$(jq -s '.[0] + .[1] + .[2]' ${configPath}/settings.json ${
              toJoplinSettings cfg
            } ${toProfileSettings cfg.profiles.Default})"
            printf '%s\n' "$config" > ${configPath}/settings.json
            unset config
          '']

          # create the profiles and write the config (except for the default profile)
          ++ (builtins.map (name: ''
            # create profile folder
            mkdir -p ${configPath}/profile-${cfg.profiles.${name}.id}
            # create config file in every profile folder
            touch ${configPath}/profile-${cfg.profiles.${name}.id}/settings.json
            # Config has to be written to temporary variable because jq cannot edit files in place.
            config="$(jq -s '.[0] + .[1]' ${configPath}/profile-${
              cfg.profiles.${name}.id
            }/settings.json ${toProfileSettings cfg.profiles.${name}})"
            # write config to file
            printf '%s\n' "$config" > ${configPath}/profile-${
              cfg.profiles.${name}.id
            }/settings.json
            unset config
          '') (lib.lists.remove "Default" (builtins.attrNames cfg.profiles)))

          # add all declared profiles to profiles.json
          ++ [''
            # create profiles.json
            touch ${configPath}/profiles.json
            # Config has to be written to temporary variable because jq cannot edit files in place.
            profiles="$(jq -s '.[0] + .[1]' ${configPath}/profiles.json ${
              toJoplinProfiles cfg.profiles
            })"
            # write config to file
            printf '%s\n' "$profiles" > ${configPath}/profiles.json
            unset profiles
          '']

          # download plugins (WIP)
          #++ (builtins.map (plugin-name: ''
          #  ${pkgs.wget}/bin/wget --output-document ${configPath}/plugins/${plugin-name}.jpl https://github.com/joplin/plugins/raw/master/plugins/${plugin-name}/plugin.jpl
          #'') cfg.plugins.installedPlugins)
        ));
    };
  };
}
