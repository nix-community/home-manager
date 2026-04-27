{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    boolToString
    mkIf
    mkOption
    types
    ;
  cfg = config.programs.pegasus-frontend;

  # providers available for use in pegasus
  validProviders = [
    "pegasus_media"
    "steam"
    "gog"
    "es2"
    "logiqx"
    "lutris"
    "skraper"
  ];

  # any string-coercable path
  typeAnyFile = types.oneOf [
    types.str
    types.package
    types.path
  ];
  # values that are valid in the config file formatter
  typeConfigValue = types.addCheck (types.oneOf [
    types.str
    (types.listOf types.str)
    (types.attrsOf types.anything) # can only be a nested typeConfigValue
  ]) (v: if lib.isAttrs v then lib.all (val: typeConfigValue.check val) (lib.attrValues v) else true);

  # flatten nested attr sets with dot notation and convert to `key.key.key: value` strings
  mkConfigString =
    data:
    let
      # flatten the attr set itself
      flatten =
        prefix: attrs:
        lib.concatMap (
          k:
          let
            v = attrs.${k};
            fullKey = if prefix == "" then k else "${prefix}.${k}";
          in
          if lib.isAttrs v && !lib.isDerivation v then
            flatten fullKey v
          else
            [
              {
                name = fullKey;
                value = v;
              }
            ]
        ) (lib.attrNames attrs);

      # properly formats a multiline string
      # https://pegasus-frontend.org/docs/dev/meta-syntax/
      processFlowingText =
        text:
        let
          lines = lib.splitString "\n" (lib.strings.trim text);
          # add tab indendation to lines
          processedLines = map (
            line:
            let
              trimmed = lib.strings.trim line;
            in
            # empty lines are replaced with a '.'
            if trimmed == "" then "\t." else "\t${trimmed}"
          ) lines;
        in
        lib.concatStringsSep "\n" processedLines;
    in
    lib.generators.toKeyValue {
      mkKeyValue =
        k: v:
        "${k}: ${if lib.isString v && lib.strings.hasInfix "\n" v then "\n${processFlowingText v}" else v}";
      listsAsDuplicateKeys = true; # lists will be converted to duplicate keys, which the format supports
    } (builtins.listToAttrs (flatten "" data));

  # generates a single metadata file containing all games
  mkGamesConfig =
    games:
    lib.concatMapStringsSep "\n\n" (
      game:
      let
        gameAttrs =
          { }
          // lib.optionalAttrs (game.sortBy != null) {
            "sort-by" = game.sortBy;
          }
          // lib.optionalAttrs (game.files != null && game.files != [ ]) {
            file = map (v: "${v}") game.files;
          }
          // lib.optionalAttrs (game.developers != null && game.developers != [ ]) {
            developer = game.developers;
          }
          // lib.optionalAttrs (game.publishers != null && game.publishers != [ ]) {
            publisher = game.publishers;
          }
          // lib.optionalAttrs (game.genres != null && game.genres != [ ]) {
            genre = game.genres;
          }
          // lib.optionalAttrs (game.tags != null && game.tags != [ ]) {
            tag = game.tags;
          }
          // lib.optionalAttrs (game.summary != null) {
            summary = game.summary;
          }
          // lib.optionalAttrs (game.description != null) {
            description = game.description;
          }
          // lib.optionalAttrs (game.players != null) {
            players = game.players;
          }
          // lib.optionalAttrs (game.release != null) {
            release = game.release;
          }
          // lib.optionalAttrs (game.rating != null) {
            rating = game.rating;
          }
          // lib.optionalAttrs (game.launch != null) {
            launch = game.launch;
          }
          // lib.optionalAttrs (game.workdir != null) {
            workdir = game.workdir;
          }
          // lib.optionalAttrs (game.assets != null) {
            assets = lib.mapAttrs (
              _: v: # convert derivation paths to strings
              if lib.isList v then map (item: "${item}") v else "${v}"
            ) game.assets;
          }
          // game.extraConfig;
      in
      ''
        game: ${game.title}
        ${mkConfigString gameAttrs}''
    ) games;

  # generates a config file for a collection definition
  mkCollectionConfig =
    name: opts:
    let
      configAttrs =
        { }
        // lib.optionalAttrs (opts.launch != null) {
          launch = opts.launch;
        }
        // lib.optionalAttrs (opts.workdir != null) {
          workdir = opts.workdir;
        }
        // lib.optionalAttrs (opts.extensions != null) {
          extensions = lib.concatStringsSep ", " opts.extensions;
        }
        // lib.optionalAttrs (opts.files != null) {
          file = map (v: "${v}") opts.files;
        }
        // lib.optionalAttrs (opts.regex != null) {
          regex = opts.regex;
        }
        // lib.optionalAttrs (opts.directories != null) {
          directories = opts.directories;
        }
        // lib.optionalAttrs (opts.ignoreExtensions != null) {
          "ignore-extensions" = lib.concatStringsSep ", " opts.ignoreExtensions;
        }
        // lib.optionalAttrs (opts.ignoreFiles != null) {
          "ignore-file" = opts.ignoreFiles;
        }
        // lib.optionalAttrs (opts.ignoreRegex != null) {
          "ignore-regex" = opts.ignoreRegex;
        }
        // lib.optionalAttrs (opts.shortname != null) {
          shortname = opts.shortname;
        }
        // lib.optionalAttrs (opts.sortBy != null) {
          "sort-by" = opts.sortBy;
        }
        // lib.optionalAttrs (opts.summary != null) {
          summary = opts.summary;
        }
        // lib.optionalAttrs (opts.description != null) {
          description = opts.description;
        }
        // opts.extraConfig;
    in
    ''
      collection: ${name}
      ${mkConfigString configAttrs}'';
in
{
  meta.maintainers = [ lib.hm.maintainers.xelacodes ];

  options.programs.pegasus-frontend = {
    enable = lib.mkEnableOption "pegasus-frontend";
    package = lib.mkPackageOption pkgs "pegasus-frontend" { };

    settings = mkOption {
      type = types.submodule {
        options = {
          verifyFiles = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to verify game files on startup";
          };
          mouseSupport = mkOption {
            type = types.bool;
            default = true;
            description = "Enable mouse input support";
          };
          fullscreen = mkOption {
            type = types.bool;
            default = true;
            description = "Start in fullscreen mode";
          };
          showMissingGames = mkOption {
            type = types.bool;
            default = false;
            description = "Show all detected games, including those that may not exist";
          };
          extraConfig = mkOption {
            type = types.attrsOf typeConfigValue;
            default = { };
            description = "Additional configuration values to be merged into the settings file.";
          };
        };
      };
      default = { };
      description = "General Pegasus settings";
    };

    theme = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            package = mkOption {
              type = types.package;
              description = "The theme package to use";
            };
            name = mkOption {
              type = types.str;
              default = "theme";
              description = "The theme directory name";
            };
            settings = mkOption {
              type = types.nullOr types.attrs;
              default = null;
              description = ''
                Theme-specific settings as JSON.
                Will not be managed if not provided, meaning you can change theme settings in the UI.
              '';
            };
          };
        }
      );
      default = null;
      description = "Pegasus theme configuration";
    };

    enableProviders = mkOption {
      type = types.listOf (types.enum validProviders);
      default = validProviders;
      description = "List of enabled game providers";
    };

    keybinds = mkOption {
      type = types.submodule {
        options =
          lib.mapAttrs
            (
              name: default:
              mkOption {
                type = types.str;
                inherit default;
                description = "Key binding for ${name}";
              }
            )
            {
              "page-up" = "PgUp,GamepadL2";
              "page-down" = "PgDown,GamepadR2";
              "prev-page" = "Q,A,GamepadL1";
              "next-page" = "E,D,GamepadR1";
              "menu" = "F1,GamepadStart";
              "filters" = "F,GamepadY";
              "details" = "I,GamepadX";
              "cancel" = "Esc,Backspace,GamepadB";
              "accept" = "Return,Enter,GamepadA";
            };
      };
      default = { };
      description = "Key bindings for Pegasus controls";
    };

    gameDirs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of absolute paths to game directories";
    };

    favorites = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        List of favorite game identifiers/paths.
        YOU WILL NOT BE ABLE TO MANAGE FAVORITES IN THE UI IF THIS IS SET
      '';
    };

    # https://pegasus-frontend.org/docs/user-guide/meta-files/
    collections = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            # Basics
            launch = mkOption {
              type = types.nullOr types.str;
              default = "{file.path}"; # most games will probably be a nix store path to a binary
              description = ''
                A common launch command for the games in this collection.
                Defaults to "{file.path}". See https://pegasus-frontend.org/docs/user-guide/meta-files/#launch-command-parameters for details.
                If a game has its own custom launch command, that will override this field.
              '';
            };
            workdir = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "The default working directory used when launching a game. Defaults to the directory of the launched program.";
            };
            # Include Files
            extensions = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "A list of file extensions (without the . dot). All files with these extensions (including those in subdirectories) will be included.";
            };
            files = mkOption {
              type = types.nullOr (types.listOf typeAnyFile);
              default = null;
              description = "A single file or a list of files to add to the collection. You can use either absolute paths or paths relative to the metadata file.";
            };
            regex = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "A Perl-compatible regular expression string, without leading or trailing slashes. Relative file paths matching the regex will be included.";
            };
            directories = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "A list of directories to search for matching games.";
            };
            # Exclude Files
            ignoreExtensions = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "Similarly to `extensions`.";
            };
            ignoreFiles = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "Similarly to `files`.";
            };
            ignoreRegex = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Similarly to `regex`.";
            };
            # Metadata
            shortname = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "An optional short name for the collection, in lowercase. Often an abbreviation, like MAME, NES, etc.";
            };
            sortBy = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "An alternate name that should be used for sorting.";
            };
            summary = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "A short description of the collection in one paragraph.";
            };
            description = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "A possibly longer description of the collection.";
            };
            extraConfig = mkOption {
              type = types.attrsOf typeConfigValue;
              default = { };
              description = "Additional configuration values to be merged into the collection.";
            };
          };
        }
      );
      default = { };
      description = "Must also define games. Collections define which files in the directory should be treated as games.";
    };

    games = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            title = mkOption {
              type = types.str;
              description = "The title of the game.";
            };
            collections = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = ''
                List of collection names this game belongs to.
                Must have at least one entry to appear in the UI.
                This game will be added to the `files` of the collection(s) configuration.
              '';
            };
            favorite = mkOption {
              type = types.bool;
              default = false;
              description = "Whether this game should be marked as a favorite.";
            };

            sortBy = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "An alternate title that should be used for sorting.";
            };
            files = mkOption {
              type = types.listOf typeAnyFile;
              description = "The file path(s) that belong to this game.";
            };

            developers = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "The developer(s) of this game.";
            };
            publishers = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "The publisher(s) of this game.";
            };
            genres = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "The genre(s) of this game.";
            };
            tags = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "The tag(s) for this game.";
            };

            summary = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "A short description of the game in one paragraph.";
            };
            description = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "A possibly longer description of the game.";
            };
            players = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "The number of players who can play the game. Either a single number (eg. 2) or a number range (eg. 1-4).";
            };
            release = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "The date when the game was released, in YYYY-MM-DD format. Month and day can be omitted if unknown.";
            };
            rating = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "The rating of the game, in percentages. Either an integer percentage in the 0-100% range (eg. 70%), or a fractional value between 0 and 1 (eg. 0.7).";
            };

            launch = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "A custom launch command for this game.";
            };
            workdir = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "The working directory in which the game is launched. Defaults to the directory of the launched program.";
            };
            assets = mkOption {
              type = types.nullOr (
                types.attrsOf (
                  types.oneOf [
                    typeAnyFile
                    (types.listOf typeAnyFile)
                  ]
                )
              );
              default = null;
              description = ''
                File paths to asset files for the game.
                For a list of valid options, see https://pegasus-frontend.org/docs/themes/api/#assets
              '';
            };
            extraConfig = mkOption {
              type = types.attrsOf typeConfigValue;
              default = { };
              description = "Additional configuration values to be merged into the game.";
            };
          };
        }
      );
      default = [ ];
      description = "Must also define collections. Game entries store additional information about the individual games, such as title, developer(s) or release date.";
    };
  };

  config =
    let
      settings = cfg.settings;
      theme = cfg.theme;

      # merge games into the proper collections
      mergedCollections = lib.mapAttrs (
        collName: collOpts:
        let
          # extract all files from each game
          gameFiles = lib.concatMap (game: game.files) (
            lib.filter (game: lib.elem collName game.collections) cfg.games
          );
        in
        collOpts
        // lib.optionalAttrs (gameFiles != [ ]) {
          # merge and deduplicate file list
          files = lib.lists.unique ((lib.optionals (collOpts.files != null) collOpts.files) ++ gameFiles);
        }
      ) cfg.collections;

      # extract favorite game files and merge with favorites
      favoriteGameFiles = lib.concatMap (game: game.files) (lib.filter (game: game.favorite) cfg.games);
      mergedFavorites = lib.optionals (favoriteGameFiles != [ ] || cfg.favorites != null) (
        lib.lists.unique ((lib.optionals (cfg.favorites != null) cfg.favorites) ++ favoriteGameFiles)
      );
    in
    mkIf cfg.enable {
      warnings = lib.concatLists [
        (lib.optional (
          cfg.collections != { } && cfg.games == [ ]
        ) "pegasus-frontend: collections are defined but games are not - games won't appear in the UI")
        (lib.optional (
          cfg.games != [ ] && cfg.collections == { }
        ) "pegasus-frontend: games are defined but collections are not - games won't appear in the UI")
      ];

      home.packages = [ cfg.package ];
      xdg.configFile = {
        "pegasus-frontend/settings.txt".text = mkConfigString (
          {
            general = {
              theme = if theme == null then ":/themes/pegasus-theme-grid/" else "themes/${theme.name}/";
              verify-files = boolToString settings.verifyFiles;
              input-mouse-support = boolToString settings.mouseSupport;
              fullscreen = boolToString settings.fullscreen;
              show-missing-games = boolToString settings.showMissingGames;
            };
            providers = lib.listToAttrs (
              map (provider: {
                name = "${provider}.enabled";
                value = boolToString (lib.elem provider cfg.enableProviders);
              }) validProviders
            );
            keys = cfg.keybinds;
          }
          // settings.extraConfig
        );
        "pegasus-frontend/game_dirs.txt".text = lib.concatStringsSep "\n" (
          cfg.gameDirs
          # add the collections and games metadata if set
          ++ lib.optionals (cfg.collections != { } || cfg.games != [ ]) [
            (pkgs.runCommand "pegasus-metadata" { } (
              lib.concatStringsSep "\n" (
                [ "mkdir -p $out" ]
                # collections
                ++ lib.mapAttrsToList (
                  name: opts:
                  let # hash the name just in case
                    filename = "${lib.substring 0 32 (builtins.hashString "sha256" name)}.metadata.pegasus.txt";
                  in
                  "cp ${pkgs.writeText filename (mkCollectionConfig name opts)} $out/${filename}"
                ) mergedCollections
                # games (single file)
                ++ lib.optionals (cfg.games != [ ]) [
                  "cp ${pkgs.writeText "games.metadata.pegasus.txt" (mkGamesConfig cfg.games)} $out/games.metadata.pegasus.txt"
                ]
              )
            ))
          ]
        );
      }
      # link in theme/settings if provided
      // lib.optionalAttrs (theme != null) {
        "pegasus-frontend/themes/${theme.name}".source = theme.package;
      }
      // lib.optionalAttrs (theme != null && theme.settings != null) {
        "pegasus-frontend/theme_settings/${theme.name}.json".text = builtins.toJSON theme.settings;
      }
      # only manage favorites if they are provided
      // lib.optionalAttrs (mergedFavorites != [ ]) {
        "pegasus-frontend/favorites.txt".text = lib.concatStringsSep "\n" mergedFavorites;
      };
    };
}
