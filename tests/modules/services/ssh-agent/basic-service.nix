{ config, ... }:

{
  config = {
    services.ssh-agent = {
      enable = true;
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/systemd/user/ssh-agent.service \
        ${./basic-service-expected.service}
    '';
  };
}
