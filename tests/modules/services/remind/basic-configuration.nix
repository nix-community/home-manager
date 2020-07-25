{ config, pkgs, ... }:

{
  config = {
    services.remind = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-remind" "";
      remindFile = "/dummy/remind-file";
      remindCommand = "echo %s";
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/remind.service

      assertFileExists $serviceFile
    '';
  };
}
