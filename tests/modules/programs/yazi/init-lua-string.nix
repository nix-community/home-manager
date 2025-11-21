{
  programs.yazi = {
    enable = true;

    initLua = builtins.readFile ./init.lua;
  };

  nmt.script = ''
    assertFileContent home-files/.config/yazi/init.lua \
      ${./init.lua}
  '';
}
