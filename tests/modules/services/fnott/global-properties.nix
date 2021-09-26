{ config, lib, pkgs, ... }:

# FIXME: Deprecate on next version release of fnott (https://codeberg.org/dnkl/fnott/pulls/24).
{
  config = {
    services.fnott = {
      enable = true;
      package = config.lib.test.mkStubPackage { };

      settings = {
        main = {
          max-icon-size = 32;
          notification-margin = 5;
        };
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/fnott/fnott.ini \
        ${./global-properties-expected.ini}
    '';
  };
}
