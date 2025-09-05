{ config, ... }:

{
  config = {
    services.caffeine = {
      enable = true;
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/systemd/user/caffeine.service \
        ${./basic-service-expected.service}
    '';
  };
}
