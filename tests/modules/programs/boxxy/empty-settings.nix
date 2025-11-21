{
  config = {
    programs.boxxy.enable = true;

    nmt.script = ''
      assertPathNotExists home-files/.config/boxxy
    '';
  };
}
