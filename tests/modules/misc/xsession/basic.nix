{ config, lib, ... }:

with lib;

{
  config = {
    home.homeDirectory = "/test-home";

    xsession = {
      enable = true;
      windowManager.command = "window manager command";
      importedVariables = [ "EXTRA_IMPORTED_VARIABLE" ];
      initExtra = "init extra commands";
      profileExtra = "profile extra commands";
    };

    nmt.script = ''
      assertFileExists home-files/.xprofile
      assertFileContent \
        home-files/.xprofile \
        ${./basic-xprofile-expected.txt}

      assertFileExists home-files/.xsession
      assertFileContent \
        home-files/.xsession \
        ${./basic-xsession-expected.txt}

    '';
  };
}
