{
  programs.screen = {
    enable = true;
    screenrc = ''
      screen -t rtorrent rtorrent
      screen -t irssi irssi
      screen -t centerim centerim
      screen -t ncmpc ncmpc -c
      screen -t bash4
      screen -t bash5
      screen -t bash6
      screen -t bash7
      screen -t bash8
      screen -t bash9
      altscreen on
      term screen-256color
      bind ',' prev
      bind '.' next
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.screenrc
    assertFileContent home-files/.screenrc ${./screenrc}
  '';
}
