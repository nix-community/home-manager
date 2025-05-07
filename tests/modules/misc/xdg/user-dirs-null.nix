{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = {
    xdg.userDirs = {
      enable = true;
      desktop = null;
    };

    nmt.script = ''
      configFile=home-files/.config/user-dirs.dirs
      assertFileExists $configFile
      assertFileContent $configFile ${pkgs.writeText "expected" ''
        XDG_DOCUMENTS_DIR="$HOME/Documents"
        XDG_DOWNLOAD_DIR="$HOME/Downloads"
        XDG_MUSIC_DIR="$HOME/Music"
        XDG_PICTURES_DIR="$HOME/Pictures"
        XDG_PUBLICSHARE_DIR="$HOME/Public"
        XDG_TEMPLATES_DIR="$HOME/Templates"
        XDG_VIDEOS_DIR="$HOME/Videos"
      ''}
    '';
  };
}
