{ config, ... }:

{
  config = {
    services.gnome-keyring = {
      enable = true;
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/systemd/user/gnome-keyring.service \
        ${./basic-service-expected.service}
    '';
  };
}
