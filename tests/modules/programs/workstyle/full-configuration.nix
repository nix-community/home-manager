{
  config = {
    programs.workstyle = {
      enable = true;
      settings = {
        alice = "A";
        bob = "B";
        other = {
          fallback_icon = "F";
          deduplicate_icons = false;
          separator = ": ";
        };
      };
      systemd = {
        # Make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`
        enable = true;
        target = "sway-session.target";
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/workstyle/config.toml
      assertFileContent home-files/.config/workstyle/config.toml ${./basic-configuration.toml}

      assertFileContent \
        home-files/.config/systemd/user/workstyle.service \
        ${./systemd-user-service-expected-sway.service}
    '';
  };
}
