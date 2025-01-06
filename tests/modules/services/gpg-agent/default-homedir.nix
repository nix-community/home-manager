{ config, lib, pkgs, ... }:

with lib;

let inherit (pkgs.stdenv) isDarwin;
in {
  config = {
    services.gpg-agent.enable = true;
    services.gpg-agent.pinentryPackage =
      if isDarwin then pkgs.pinentry_mac else pkgs.pinentry-gnome3;
    programs.gpg = {
      enable = true;
      package = config.lib.test.mkStubPackage { outPath = "@gpg@"; };
    };

    test.stubs = {
      gnupg = { };
      systemd = { }; # depends on gnupg.override
      pinentry-gnome3 = { };
      pinentry_mac = { };
    };

    nmt.script = if isDarwin then ''
      serviceFile=LaunchAgents/org.nix-community.home.gpg-agent.plist
      assertFileExists "$serviceFile"
      assertFileContent "$serviceFile" ${./default-homedir-expected-agent.plist}
      configFile=home-files/.gnupg/gpg-agent.conf
      assertFileRegex $configFile "pinentry-program @pinentry_mac@/bin/dummy"
    '' else ''
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
