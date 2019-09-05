{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    xdg.mimeApps = {
      enable = true;
      associations = {
        added = {
          "mimetype1" = [ "foo1.desktop" "foo2.desktop" "foo3.desktop" ];
          "mimetype2" = "foo4.desktop";
        };
        removed = {
          mimetype1 = "foo5.desktop";
        };
      };
      defaultApplications = {
        "mimetype1" = [ "default1.desktop" "default2.desktop" ];
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/mimeapps.list
      assertFileContent \
        home-files/.config/mimeapps.list \
        ${./mime-apps-basics-expected.ini}
    '';
  };
}
