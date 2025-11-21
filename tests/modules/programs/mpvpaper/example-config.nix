{
  programs.mpvpaper = {
    enable = true;
    pauseList = ''
      firefox
      librewolf
      steam
    '';
    stopList = ''
      obs
      virt-manager
      gimp
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/mpvpaper/pauselist
    assertFileExists home-files/.config/mpvpaper/stoplist
    assertFileContent home-files/.config/mpvpaper/pauselist \
    ${./pauselist}
    assertFileContent home-files/.config/mpvpaper/stoplist \
    ${./stoplist}
  '';
}
