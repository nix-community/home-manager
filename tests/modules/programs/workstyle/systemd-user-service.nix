{
  config = {
    programs.workstyle = {
      enable = true;
      systemd = {
        enable = true;
        debug = true;
        target = "a.target";
      };
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/workstyle/config.toml

      assertFileContent \
        home-files/.config/systemd/user/workstyle.service \
        ${./systemd-user-service-expected-debug.service}
    '';
  };
}
