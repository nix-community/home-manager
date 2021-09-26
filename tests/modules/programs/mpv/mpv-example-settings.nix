{ config, lib, pkgs, ... }:

{
  config = {
    programs.mpv = {
      enable = true;
      package = pkgs.mpvDummy;

      bindings = {
        WHEEL_UP = "seek 10";
        WHEEL_DOWN = "seek -10";
        "Alt+0" = "set window-scale 0.5";
      };

      config = {
        force-window = true;
        ytdl-format = "bestvideo+bestaudio";
        cache-default = 4000000;
      };

      profiles = {
        fast = { vo = "vdpau"; };
        "protocol.dvd" = {
          profile-desc = "profile for dvd:// streams";
          alang = "en";
        };
      };

      defaultProfiles = [ "gpu-hq" ];
    };

    test.stubs.mpvDummy = { };

    nmt.script = ''
      assertFileContent \
         home-files/.config/mpv/mpv.conf \
         ${./mpv-example-settings-expected-config}
      assertFileContent \
         home-files/.config/mpv/input.conf \
         ${./mpv-example-settings-expected-bindings}
    '';
  };

}
