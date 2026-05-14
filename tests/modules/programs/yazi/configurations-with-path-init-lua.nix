{
  programs.yazi = {
    enable = true;

    plugins = {
      dual-pane = {
        package = ./plugin;
        setup = true;
      };
    };

    initLua = ./init.lua;
  };

  nmt.script = ''
    assertFileContent home-files/.config/yazi/init.lua \
      ${./configurations-with-init-lua-expected.lua}
  '';
}
