{ config, lib, pkgs, ... }:

{
  config = {
    xdg.userDirs = {
      enable = true;
      desktop = null;
    };

    nmt.script = ''
      configFile=home-files/.config/user-dirs.dirs
      assertFileExists $configFile
      assertFileContent $configFile ${
        pkgs.writeText "expected" ''
          XDG_DOCUMENTS_DIR="/home/hm-user/Documents"
          XDG_DOWNLOAD_DIR="/home/hm-user/Downloads"
          XDG_MUSIC_DIR="/home/hm-user/Music"
          XDG_PICTURES_DIR="/home/hm-user/Pictures"
          XDG_PUBLICSHARE_DIR="/home/hm-user/Public"
          XDG_TEMPLATES_DIR="/home/hm-user/Templates"
          XDG_VIDEOS_DIR="/home/hm-user/Videos"
        ''
      }
    '';
  };
}
