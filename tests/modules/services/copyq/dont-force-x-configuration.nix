{ ... }:

{
  config = {
    services.copyq = {
      enable = true;
      forceXWayland = false;
    };

    test.stubs.copyq = { };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/copyq.service
      assertFileContent $serviceFile ${./dont-force-x-expected.service}
    '';
  };
}
