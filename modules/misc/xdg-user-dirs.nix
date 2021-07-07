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
        Whether to manage <filename>$XDG_CONFIG_HOME/user-dirs.dirs</filename>.
        </para>
        <para>
        The generated file is read-only.
      '';
    };

    # Well-known directory list from
    # https://gitlab.freedesktop.org/xdg/xdg-user-dirs/blob/master/man/user-dirs.dirs.xml

    desktop = mkOption {
      type = types.str;
      default = "$HOME/Desktop";
      description = "The Desktop directory.";
    };

    documents = mkOption {
      type = types.str;
      default = "$HOME/Documents";
      description = "The Documents directory.";
    };

    download = mkOption {
      type = types.str;
      default = "$HOME/Downloads";
      description = "The Downloads directory.";
    };

    music = mkOption {
      type = types.str;
      default = "$HOME/Music";
      description = "The Music directory.";
    };

    pictures = mkOption {
      type = types.str;
      default = "$HOME/Pictures";
      description = "The Pictures directory.";
    };

    publicShare = mkOption {
      type = types.str;
      default = "$HOME/Public";
      description = "The Public share directory.";
    };

    templates = mkOption {
      type = types.str;
      default = "$HOME/Templates";
      description = "The Templates directory.";
    };

    videos = mkOption {
      type = types.str;
      default = "$HOME/Videos";
      description = "The Videos directory.";
    };

    extraConfig = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = { XDG_MISC_DIR = "$HOME/Misc"; };
      description = "Other user directories.";
    };

    createDirectories =
      mkEnableOption "automatic creation of the XDG user directories";
  };

  config = let
    directories = {
      XDG_DESKTOP_DIR = cfg.desktop;
      XDG_DOCUMENTS_DIR = cfg.documents;
      XDG_DOWNLOAD_DIR = cfg.download;
      XDG_MUSIC_DIR = cfg.music;
      XDG_PICTURES_DIR = cfg.pictures;
      XDG_PUBLICSHARE_DIR = cfg.publicShare;
      XDG_TEMPLATES_DIR = cfg.templates;
      XDG_VIDEOS_DIR = cfg.videos;
    } // cfg.extraConfig;
  in mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "xdg.userDirs" pkgs platforms.linux) ];

    xdg.configFile."user-dirs.dirs".text = let
      # For some reason, these need to be wrapped with quotes to be valid.
      wrapped = mapAttrs (_: value: ''"${value}"'') directories;
    in generators.toKeyValue { } wrapped;

    xdg.configFile."user-dirs.conf".text = "enabled=False";

    home.activation = mkIf cfg.createDirectories {
      createXdgUserDirectories = let
        directoriesList = attrValues directories;
        mkdir = (dir: ''$DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${dir}"'');
      in lib.hm.dag.entryAfter [ "writeBoundary" ]
      (strings.concatMapStringsSep "\n" mkdir directoriesList);
    };
  };
}
