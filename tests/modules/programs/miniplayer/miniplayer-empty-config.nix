{ config, lib, pkgs, ... }:

{
  config = {
    programs.miniplayer = {
      enable = true;
      imageMethod = "ueberzug";
    };

    test.stubs.miniplayerDummy = { };

    nmt.script = ''
      assertFileContent \
        home-files/.config/miniplayer/config \
        ${./miniplayer-expected-empty-config}
    '';
  };
}
