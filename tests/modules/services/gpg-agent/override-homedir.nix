{ config, lib, pkgs, ... }:

with lib;

let inherit (pkgs.stdenv) isDarwin;
in {
  config = {
    services.gpg-agent.enable = true;
    services.gpg-agent.pinentryPackage = null; # Don't build pinentry package.
    programs.gpg = {
      enable = true;
      homedir = "/path/to/hash";
      package = config.lib.test.mkStubPackage { outPath = "@gpg@"; };
    };

    test.stubs.gnupg = { };
    test.stubs.systemd = { }; # depends on gnupg.override

    nmt.script = if isDarwin then ''
      serviceFile=LaunchAgents/org.nix-community.home.gpg-agent.plist
      assertFileExists "$serviceFile"
      assertFileContent "$serviceFile" ${./expected-agent.plist}
    '' else ''
      in="${config.systemd.user.sockets.gpg-agent.Socket.ListenStream}"
      if [[ $in != "%t/gnupg/d.wp4h7ks5zxy4dodqadgpbbpz/S.gpg-agent" ]]
      then
        echo $in
        fail "gpg-agent socket directory is malformed"
      fi
    '';
  };
}
