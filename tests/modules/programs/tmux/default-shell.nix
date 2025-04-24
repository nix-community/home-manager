{
  config = {
    programs.tmux = {
      enable = true;
      shell = "/usr/bin/myshell";
    };

    nmt.script = ''
      assertFileExists home-files/.config/tmux/tmux.conf
      assertFileContent home-files/.config/tmux/tmux.conf ${./default-shell.conf}
    '';
  };
}
