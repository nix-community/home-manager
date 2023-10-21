{ config, pkgs, ... }:

{
  services.darkman = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "darkman";
      outPath = "@darkman@";
    };

    settings.lat = 50.8;
    settings.lng = 4.4;
    settings.usegeoclue = true;

    darkModeScripts.color-scheme-dark = ''
      dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
    '';

    lightModeScripts.color-scheme-light = pkgs.writeScript "my-python-script" ''
      #!${pkgs.python}/bin/python

      print('Do something!')
    '';
  };

  test.stubs.python = { };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/darkman.service)
    darkModeScriptFile=$(normalizeStorePaths home-files/.local/share/dark-mode.d/color-scheme-dark)
    lightModeScriptFile=$(normalizeStorePaths home-files/.local/share/light-mode.d/color-scheme-light)

    assertFileExists $serviceFile
    assertFileContent $serviceFile ${
      builtins.toFile "expected" ''
        [Install]
        WantedBy=graphical-session.target

        [Service]
        BusName=nl.whynothugo.darkman
        ExecStart=@darkman@/bin/darkman run
        Restart=on-failure
        Slice=background.slice
        TimeoutStopSec=15
        Type=dbus

        [Unit]
        BindsTo=graphical-session.target
        Description=Darkman system service
        Documentation=man:darkman(1)
        PartOf=graphical-session.target
        X-Restart-Triggers=/nix/store/00000000000000000000000000000000-darkman-config.yaml
      ''
    }
    assertFileContent $darkModeScriptFile ${
      builtins.toFile "expected" ''
        #!/nix/store/00000000000000000000000000000000-bash/bin/bash
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"

      ''
    }
    assertFileContent $lightModeScriptFile ${
      builtins.toFile "expected" ''
        #!@python@/bin/python

        print('Do something!')
      ''
    }
  '';
}
