{ pkgs, ... }:

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

      serviceFile=home-files/.config/systemd/user/wpaperd.service
      assertFileExists $serviceFile
      assertFileContent $serviceFile \
        ${
          pkgs.writeText "wpaperd-expected.service" ''
            [Install]
            WantedBy=graphical-session.target

            [Service]
            ExecStart=${pkgs.wpaperd}/bin/wpaperd

            [Unit]
            After=graphical-session-pre.target
            Description=Modern wallpaper daemon for Wayland
            PartOf=graphical-session.target
          ''
        }

    '';
  };
}
