{ config, ... }:

{

  programs.swayimg = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    initLua = ./example-initLua-expected.lua;
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/swayimg/init.lua \
      ${./example-initLua-expected.lua}
  '';
}
