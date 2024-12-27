{ ... }:

{
  config = {
    services.copyq = {
      enable = true;
      systemdTarget = "sway-session.target";
    };

    test.stubs.copyq = { };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/copyq.service
      assertFileContent $serviceFile ${./basic-expected.service}
    '';
  };
}
