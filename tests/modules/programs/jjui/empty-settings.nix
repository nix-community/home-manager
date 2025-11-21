{
  config = {
    programs.jjui.enable = true;

    nmt.script = ''
      assertPathNotExists home-files/.config/jjui
    '';
  };
}
