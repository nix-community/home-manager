{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xdg.userDirs;

in {
  meta.maintainers = with maintainers; [ pacien ];

  imports = [
    (mkRenamedOptionModule [ "xdg" "userDirs" "publishShare" ] [
      "xdg"
      "userDirs"
      "publicShare"
    ])
  ];

  options.xdg.userDirs = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to manage {file}`$XDG_CONFIG_HOME/user-dirs.dirs`.

        The generated file is read-only.
      '';
    };

    # Well-known directory list from
    # https://gitlab.freedesktop.org/xdg/xdg-user-dirs/blob/master/man/user-dirs.dirs.xml

    desktop = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Desktop";
      defaultText =
        literalExpression ''"''${config.home.homeDirectory}/Desktop"'';
      description = "The Desktop directory.";
    };

    documents = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Documents";
      defaultText =
        literalExpression ''"''${config.home.homeDirectory}/Documents"'';
      description = "The Documents directory.";
    };

    download = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Downloads";
      defaultText =
        literalExpression ''"''${config.home.homeDirectory}/Downloads"'';
      description = "The Downloads directory.";
    };

    music = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Music";
      defaultText =
        literalExpression ''"''${config.home.homeDirectory}/Music"'';
      description = "The Music directory.";
    };

    pictures = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Pictures";
      defaultText =
        literalExpression ''"''${config.home.homeDirectory}/Pictures"'';
      description = "The Pictures directory.";
    };

    publicShare = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Public";
      defaultText =
        literalExpression ''"''${config.home.homeDirectory}/Public"'';
      description = "The Public share directory.";
    };

    templates = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Templates";
      defaultText =
        literalExpression ''"''${config.home.homeDirectory}/Templates"'';
      description = "The Templates directory.";
    };

    videos = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Videos";
      defaultText =
        literalExpression ''"''${config.home.homeDirectory}/Videos"'';
      description = "The Videos directory.";
    };

    extraConfig = mkOption {
      type = with types; attrsOf (coercedTo path toString str);
      default = { };
      defaultText = literalExpression "{ }";
      example = literalExpression ''
        {
          XDG_MISC_DIR = "''${config.home.homeDirectory}/Misc";
        }
      '';
      description = "Other user directories.";
    };

    createDirectories =
      mkEnableOption "automatic creation of the XDG user directories";
  };

  config = let
    directories = (filterAttrs (n: v: !isNull v) {
      XDG_DESKTOP_DIR = cfg.desktop;
      XDG_DOCUMENTS_DIR = cfg.documents;
      XDG_DOWNLOAD_DIR = cfg.download;
      XDG_MUSIC_DIR = cfg.music;
      XDG_PICTURES_DIR = cfg.pictures;
      XDG_PUBLICSHARE_DIR = cfg.publicShare;
      XDG_TEMPLATES_DIR = cfg.templates;
      XDG_VIDEOS_DIR = cfg.videos;
    }) // cfg.extraConfig;
  in mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "xdg.userDirs" pkgs platforms.linux) ];

    xdg.configFile."user-dirs.dirs".text = let
      # For some reason, these need to be wrapped with quotes to be valid.
      wrapped = mapAttrs (_: value: ''"${value}"'') directories;
    in generators.toKeyValue { } wrapped;

    xdg.configFile."user-dirs.conf".text = "enabled=False";

    home.sessionVariables = directories;

    home.activation.createXdgUserDirectories = mkIf cfg.createDirectories (let
      directoriesList = attrValues directories;
      mkdir =
        (dir: ''[[ -L "${dir}" ]] || run mkdir -p $VERBOSE_ARG "${dir}"'');
    in lib.hm.dag.entryAfter [ "linkGeneration" ]
    (strings.concatMapStringsSep "\n" mkdir directoriesList));
  };
}
