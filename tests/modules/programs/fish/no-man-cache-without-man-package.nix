{
  config = {
    home.stateVersion = "26.05";

    programs.man.package = null;
    programs.fish.enable = true;

    nmt.script = ''
      assertPathNotExists home-files/.manpath
    '';
  };
}
