{
  config,
  pkgs,
  ...
}:

{
  config = {
    home.stateVersion = "25.11";

    xdg.userDirs = {
      enable = true;
      extraConfig.PROJECTS = "${config.home.homeDirectory}/Projects";
      ## This will trigger a warning.
      extraConfig.XDG_MISC_DIR = "${config.home.homeDirectory}/Misc";
    };

    nmt.script = ''
      configFile=home-files/.config/user-dirs.dirs
      assertFileExists $configFile
      assertFileContent $configFile ${pkgs.writeText "expected" ''
        XDG_DESKTOP_DIR="/home/hm-user/Desktop"
        XDG_DOCUMENTS_DIR="/home/hm-user/Documents"
        XDG_DOWNLOAD_DIR="/home/hm-user/Downloads"
        XDG_MISC_DIR="/home/hm-user/Misc"
        XDG_MUSIC_DIR="/home/hm-user/Music"
        XDG_PICTURES_DIR="/home/hm-user/Pictures"
        XDG_PROJECTS_DIR="/home/hm-user/Projects"
        XDG_PUBLICSHARE_DIR="/home/hm-user/Public"
        XDG_TEMPLATES_DIR="/home/hm-user/Templates"
        XDG_VIDEOS_DIR="/home/hm-user/Videos"
      ''}
    '';
  };
}
