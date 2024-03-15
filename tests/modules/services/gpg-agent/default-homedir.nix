{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    services.gpg-agent.enable = true;
    services.gpg-agent.pinentryPackage = pkgs.pinentry-gnome3;
    programs.gpg.enable = true;

    test.stubs = {
      gnupg = { };
      systemd = { }; # depends on gnupg.override
      pinentry-gnome3 = { };
    };

    nmt.script = ''
      in="${config.systemd.user.sockets.gpg-agent.Socket.ListenStream}"
      if [[ $in != "%t/gnupg/S.gpg-agent" ]]
      then
        echo $in
        fail "gpg-agent socket directory not set to default value"
      fi

      configFile=home-files/.gnupg/gpg-agent.conf
      assertFileRegex $configFile "pinentry-program @pinentry-gnome3@/bin/dummy"
    '';
  };
}
