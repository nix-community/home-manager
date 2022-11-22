{ config, lib, pkgs, ... }:

{
  config = {
    programs.miniplayer = {
      enable = true;
      imageMethod = "ueberzug";
    };

    services.mpd.enable = true;

    test.stubs.miniplayerDummy = { };

    nmt.script = ''
      assertFileContent \
        home-files/.config/miniplayer/config \
        ${./miniplayer-expected-config}
    '';
  };
}
