{ config, lib, pkgs, ... }:

{
  config = {
    services.fnott = {
      enable = true;
      package = config.lib.test.mkStubPackage { };

      settings = {
        main = { notification-margin = 5; };

        low = {
          timeout = 5;
          title-font = "Dina:weight=bold:slant=italic";
          title-color = "ffffff";
        };
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/fnott/fnott.ini \
        ${./example-settings-expected.ini}
    '';
  };
}
