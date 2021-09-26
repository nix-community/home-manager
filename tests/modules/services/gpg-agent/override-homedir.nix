{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    services.gpg-agent.enable = true;
    programs.gpg = {
      enable = true;
      homedir = "${config.home.homeDirectory}/foo/bar";
    };

    test.stubs.gnupg = { };

    nmt.script = ''
      in="${config.systemd.user.sockets.gpg-agent.Socket.ListenStream}"
      if [[ $in != "%t/gnupg/d."????????????????????????"/S.gpg-agent" ]]
      then
        echo $in
        fail "gpg-agent socket directory is malformed"
      fi
    '';
  };
}
