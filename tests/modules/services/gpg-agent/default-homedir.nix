{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    services.gpg-agent.enable = true;
    programs.gpg.enable = true;

    test.stubs.gnupg = { };

    nmt.script = ''
      in="${config.systemd.user.sockets.gpg-agent.Socket.ListenStream}"
      if [[ $in != "%t/gnupg/S.gpg-agent" ]]
      then
        echo $in
        fail "gpg-agent socket directory not set to default value"
      fi
    '';
  };
}
