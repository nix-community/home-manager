{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xdg.userDirs;

in

{
  meta.maintainers = with maintainers; [ pacien ];

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

    publishShare = mkOption {
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
  };

  config = mkIf cfg.enable {
    xdg.configFile."user-dirs.dirs".text = generators.toKeyValue {} (
      {
        XDG_DESKTOP_DIR = cfg.desktop;
        XDG_DOCUMENTS_DIR = cfg.documents;
        XDG_DOWNLOAD_DIR = cfg.download;
        XDG_MUSIC_DIR = cfg.music;
        XDG_PICTURES_DIR = cfg.pictures;
        XDG_PUBLICSHARE_DIR = cfg.publishShare;
        XDG_TEMPLATES_DIR = cfg.templates;
        XDG_VIDEOS_DIR = cfg.videos;
      }
      // cfg.extraConfig
    );
  };
}
