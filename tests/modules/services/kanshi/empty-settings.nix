{ config, ... }:
{
  config = {
    services.kanshi = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/kanshi.service

      assertFileExists $serviceFile
      assertFileContent \
        $(normalizeStorePaths $serviceFile) \
        ${./empty-settings.service}
    '';
  };
}
