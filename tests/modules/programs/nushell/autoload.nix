{ pkgs, config, ... }: {
  programs.nushell = {
    enable = true;
    autoload = [
      {
        name = "cow.nu";
        content = ''
          #!/usr/bin/env nu
          def cow [] {
            print "Mooooooooooo"
          }
        '';
      }
      {
        name = "cow2.nu";
        content = ./autoload-cow;
      }
      ./autoload.nu
    ];
  };

  nmt.script =
    let
      autoloadDir =
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "home-files/Library/Application Support/nushell/autoload"
        else
          "home-files/.config/nushell/autoload";
    in
    ''
      assertFileExists "${autoloadDir}/cow.nu"
      assertFileContent "${autoloadDir}/cow.nu" ${./autoload-cow}
      assertFileExists "${autoloadDir}/cow2.nu"
      assertFileContent "${autoloadDir}/cow2.nu" ${./autoload-cow}
      assertFileExists "${autoloadDir}/autoload.nu"
      assertFileContent "${autoloadDir}/autoload.nu" ${./autoload.nu}
    '';
}
