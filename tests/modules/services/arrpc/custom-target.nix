{
  config = {
    services.arrpc = {
      enable = true;
      systemdTarget = "sway-session.target";
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/systemd/user/arRPC.service \
        ${./custom-target-expected.service}
    '';
  };
}
