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

  # any config value, coerced to a string
  configValueType = types.coercedTo (types.oneOf [
    types.path
    types.package
    types.int
  ]) (x: if builtins.isInt x then toString x else "${x}") types.str;
  # config file type, coerce paths/packages to a string path
  configType = types.attrsOf (types.either configValueType (types.listOf configValueType));

  # flatten nested attr sets with dot notation and convert to `key.key.key: value` strings
  mkConfigString =
    data:
    let
      # recursively flatten the attr set
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

      # properly formats a multiline string with tab characters
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
    lib.concatMapStringsSep "\n\n" (game: ''
      game: ${game.title}
      ${mkConfigString (
        removeAttrs game [
          "title"
          # these are internal to the module
          "collections"
          "favorite"
        ]
      )}'') games;

  # generates a config file for a collection definition
  mkCollectionConfig = name: opts: ''
    collection: ${name}
    ${mkConfigString opts}'';
in
{
  meta.maintainers = [ lib.maintainers.xelacodes ];

  options.programs.pegasus-frontend = {
    enable = lib.mkEnableOption "pegasus-frontend";
    package = lib.mkPackageOption pkgs "pegasus-frontend" { nullable = true; };

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
            type = types.attrsOf configType;
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
              type = types.nullOr ((pkgs.formats.json { }).type);
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
            # defaults from upstream
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
          freeformType = configType;
          # most games will probably be a nix store path to a binary, so set it as default
          config.launch = lib.mkDefault "{file.path}";
        }
      );
      default = { };
      description = ''
        Must also define games. Collections define which files in the directory should be treated as games.
        See https://pegasus-frontend.org/docs/user-guide/meta-files/ for options.
      '';
    };

    games = mkOption {
      type = types.listOf (
        types.submodule {
          freeformType = configType;

          options = {
            # internal
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
              description = ''
                Whether this game should be marked as a favorite.
                YOU WILL NOT BE ABLE TO MANAGE FAVORITES IN THE UI IF THIS IS SET
              '';
            };

            # part of the spec, but required for the module
            title = mkOption {
              type = types.str;
              description = "The title of the game.";
            };
            files = mkOption {
              type = types.listOf configValueType;
              description = "The file path(s) that belong to this game.";
            };
            assets = mkOption {
              type = types.attrsOf (
                types.oneOf [
                  configValueType
                  (types.listOf configValueType)
                ]
              );
              default = { };
              description = ''
                File paths to asset files for the game.
                For a list of valid options, see https://pegasus-frontend.org/docs/themes/api/#assets
              '';
            };
          };
        }
      );
      default = [ ];
      description = ''
        Must also define collections. Game entries store additional information about the individual games, such as title, developer(s) or release date.
        See https://pegasus-frontend.org/docs/user-guide/meta-files/ for options.
      '';
    };
  };

  config =
    let
      inherit (cfg) settings;
      inherit (cfg) theme;

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
          files = lib.lists.unique ((lib.optionals (collOpts ? files) collOpts.files) ++ gameFiles);
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

      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
      xdg.configFile = {
        "pegasus-frontend/settings.txt".text = mkConfigString (
          lib.recursiveUpdate {
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
          } settings.extraConfig
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
