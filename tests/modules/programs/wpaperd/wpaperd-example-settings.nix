{ ... }:

{
  config = {
    programs.wpaperd = {
      enable = true;
      settings = {
        eDP-1 = {
          path = "/home/foo/Pictures/Wallpaper";
          apply-shadow = true;
        };
        DP-2 = {
          path = "/home/foo/Pictures/Anime";
          sorting = "descending";
        };
      };
    };

    test.stubs.wpaperd = { };

    nmt.script = ''
      assertFileContent home-files/.config/wpaperd/wallpaper.toml \
        ${./wpaperd-expected-settings.toml}
    '';
  };
}
