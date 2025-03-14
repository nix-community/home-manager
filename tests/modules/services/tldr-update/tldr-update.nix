{ config, ... }:

{
  config = {
    home.stateVersion = "24.11";

    services.tldr-update = {
      enable = true;
      package = config.lib.test.mkStubPackage { outPath = "@tldr@"; };
      period = "monthly";
    };

    nmt.script = ''
      serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/tldr-update.service)
      assertFileContent "$serviceFile" ${./tldr-update.service}

      timerFile=$(normalizeStorePaths home-files/.config/systemd/user/tldr-update.timer)
      assertFileContent "$timerFile" ${./tldr-update.timer}
    '';
  };
}
