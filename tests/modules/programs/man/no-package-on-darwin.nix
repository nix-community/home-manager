{
  config = {
    home.stateVersion = "26.05";

    programs.man.enable = true;

    nmt.script = ''
      assertPathNotExists home-path/bin/man
      assertPathNotExists home-files/.manpath
    '';
  };
}
