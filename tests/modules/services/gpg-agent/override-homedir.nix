{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    services.gpg-agent.enable = true;
    services.gpg-agent.pinentryFlavor = null; # Don't build pinentry package.
    programs.gpg = {
      enable = true;
      homedir = "/path/to/hash";
    };

    test.stubs.gnupg = { };
    test.stubs.systemd = { }; # depends on gnupg.override

    nmt.script = ''
      in="${config.systemd.user.sockets.gpg-agent.Socket.ListenStream}"
      if [[ $in != "%t/gnupg/d.wp4h7ks5zxy4dodqadgpbbpz/S.gpg-agent" ]]
      then
        echo $in
        fail "gpg-agent socket directory is malformed"
      fi
    '';
  };
}
