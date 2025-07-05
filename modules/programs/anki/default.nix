{
  lib,
  config,
  pkgs,
  ...
}:
let
  helper = import ./helper.nix { inherit lib config pkgs; };

  ankiBaseDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Anki2"
    else
      "${config.xdg.dataHome}/Anki2";
  cfg = config.programs.anki;
in
{
  meta.maintainers = [ lib.maintainers.junestepp ];

  options.programs.anki = {
    enable = lib.mkEnableOption "Anki";

    package = lib.mkPackageOption pkgs "anki" { };

    language = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "en_US";
      description = ''
        Display language. Should be an underscore separated language tag.
        See <https://github.com/ankitects/anki/blob/main/pylib/anki/lang.py> for
        supported tags.
      '';
    };

    videoDriver = lib.mkOption {
      type =
        with lib.types;
        nullOr (enum [
          "opengl"
          "angle"
          "software"
          "metal"
          "vulkan"
          "d3d11"
        ]);
      default = null;
      example = "opengl";
      description = "Video driver to use.";
    };

    theme = lib.mkOption {
      type =
        with lib.types;
        nullOr (enum [
          "followSystem"
          "light"
          "dark"
        ]);
      default = null;
      example = "dark";
      description = "Theme to use.";
    };

    style = lib.mkOption {
      type =
        with lib.types;
        nullOr (enum [
          "anki"
          "native"
        ]);
      default = null;
      example = "native";
      description = "Widgets style.";
    };

    uiScale = lib.mkOption {
      type = with lib.types; nullOr (numbers.between 0.0 1.0);
      default = null;
      example = 1.0;
      description = "User interface scale.";
    };

    hideTopBar = lib.mkOption {
      type = with lib.types; nullOr bool;
      default = null;
      example = true;
      description = "Hide top bar during review.";
    };
    hideTopBarMode = lib.mkOption {
      type =
        with lib.types;
        nullOr (enum [
          "fullscreen"
          "always"
        ]);
      default = null;
      example = "fullscreen";
      description = "When to hide the top bar when `hideTopBar` is enabled.";
    };

    hideBottomBar = lib.mkOption {
      type = with lib.types; nullOr bool;
      default = null;
      example = true;
      description = "Hide bottom bar during review.";
    };
    hideBottomBarMode = lib.mkOption {
      type =
        with lib.types;
        nullOr (enum [
          "fullscreen"
          "always"
        ]);
      default = null;
      example = "fullscreen";
      description = "When to hide the bottom bar when `hideBottomBar` is enabled.";
    };

    reduceMotion = lib.mkOption {
      type = with lib.types; nullOr bool;
      default = null;
      example = true;
      description = "Disable various animations and transitions of the user interface.";
    };

    minimalistMode = lib.mkOption {
      type = with lib.types; nullOr bool;
      default = null;
      example = true;
      description = "Minimalist user interface mode.";
    };

    spacebarRatesCard = lib.mkOption {
      type = with lib.types; nullOr bool;
      default = null;
      example = true;
      description = "Spacebar (or enter) also answers card.";
    };

    legacyImportExport = lib.mkOption {
      type = with lib.types; nullOr bool;
      default = null;
      description = "Use legacy (pre 2.1.55) import/export handling code.";
    };

    answerKeys = lib.mkOption {
      type =
        with lib.types;
        listOf (submodule {
          options = {
            ease = lib.mkOption {
              type = with lib.types; int;
              example = 3;
              description = ''
                Number associated with an answer button.

                By default, 1 = Again, 2 = Hard, 3 = Good, and 4 = Easy.
              '';
            };
            key = lib.mkOption {
              type = with lib.types; str;
              example = "3";
              description = ''
                Keyboard shortcut for this answer button. The shortcut should be in
                the string format used by <https://doc.qt.io/qt-6/qkeysequence.html>.
              '';
            };
          };
        });
      default = [ ];
      example = [
        {
          ease = 1;
          key = "left";
        }
        {
          ease = 2;
          key = "up";
        }
        {
          ease = 3;
          key = "right";
        }
        {
          ease = 4;
          key = "down";
        }
      ];
      description = ''
        Overrides for choosing what keyboard shortcut activates each
        answer button. The Anki default will be used for ones without an
        override defined.
      '';
    };

    sync = {
      username = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "lovelearning@email.com";
        description = "Sync account username.";
      };

      usernameFile = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
        description = "Path to a file containing the sync account username.";
      };

      passwordFile = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
        description = "Path to a file containing the sync account password.";
      };

      url = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "http://example.com/anki-sync/";
        description = ''
          Custom sync server URL. See <https://docs.ankiweb.net/sync-server.html>.
        '';
      };

      autoSync = lib.mkOption {
        type = with lib.types; nullOr bool;
        default = null;
        example = true;
        description = "Automatically sync on profile open/close.";
      };

      syncMedia = lib.mkOption {
        type = with lib.types; nullOr bool;
        default = null;
        example = true;
        description = "Synchronize audio and images too.";
      };

      autoSyncMediaMinutes = lib.mkOption {
        type = with lib.types; nullOr ints.unsigned;
        default = null;
        example = 15;
        description = ''
          Automatically sync media every X minutes. Set this to 0 to disable
          periodic media syncing.
        '';
      };

      networkTimeout = lib.mkOption {
        type = with lib.types; nullOr ints.unsigned;
        default = null;
        example = 60;
        description = "Network timeout in seconds.";
      };
    };

    addons = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      example = lib.literalExpression ''
        [
          # When the add-on is already available in nixpkgs
          pkgs.ankiAddons.anki-connect

          # When the add-on is not available in nixpkgs
          (pkgs.anki-utils.buildAnkiAddon (finalAttrs: {
            pname = "recolor";
            version = "3.1";
            src = pkgs.fetchFromGitHub {
              owner = "AnKing-VIP";
              repo = "AnkiRecolor";
              rev = finalAttrs.version;
              sparseCheckout = [ "src/addon" ];
              hash = "sha256-28DJq2l9DP8O6OsbNQCZ0pm4S6CQ3Yz0Vfvlj+iQw8Y=";
            };
            sourceRoot = "''${finalAttrs.src.name}/src/addon";
          }))

          # When the add-on needs to be configured
          pkgs.ankiAddons.passfail2.withConfig {
            config = {
              again_button_name = "not quite";
              good_button_name = "excellent";
            };
            user_files = ./dir-to-be-merged-into-addon-user-files-dir;
          };
        ]
      '';
      description = "List of Anki add-on packages to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.sync.username != null && cfg.sync.usernameFile != null);
        message = ''
          The `programs.anki.sync` `username` option is mutually exclusive with
          the `usernameFile` option.
        '';
      }
      {
        assertion = cfg.package ? withAddons;
        message = ''
          The value of `programs.anki.package` doesn't support declaratively managing
          add-ons. Make sure you are using `pkgs.anki`.
        '';
      }
    ];

    home.packages = [
      (cfg.package.withAddons (
        [
          helper.homeManagerAnkiAddon
          helper.syncConfigAnkiAddon
        ]
        ++ cfg.addons
      ))
    ];

    home.file."${ankiBaseDir}/gldriver6" = lib.mkIf (cfg.videoDriver != null) {
      source = "${helper.ankiConfig}/gldriver6";
    };
    home.file."${ankiBaseDir}/prefs21.db".source = "${helper.ankiConfig}/prefs21.db";
  };
}
