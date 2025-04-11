{ config, ... }:
{
  config = {
    services.way-displays = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      settings = {
        CALLBACK_CMD = "notify-send \"way-displays \${CALLBACK_LEVEL}\" \"\${CALLBACK_MSG}\"";
        ORDER = [
          "eDP-1"
          "DELL U2419HC"
          "DELL U2415"
          "HP E24 G5"
          "HP E24 G5"
        ];
        ALIGN = "MIDDLE";
        VRR_OFF = [
          "DELL U2419HC"
          "DELL U2415"
        ];
        TRANSFORM = [
          {
            NAME_DESC = "DELL U2419HC";
            TRANSFORM = "90";
          }
          {
            NAME_DESC = "HP E24 G5";
            TRANSFORM = "90";
          }
        ];
      };
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/way-displays.service
      assertFileExists $serviceFile

      assertFileExists home-files/.config/way-displays/cfg.yaml
      assertFileContent home-files/.config/way-displays/cfg.yaml \
                ${./configuration.yaml}
    '';
  };
}
