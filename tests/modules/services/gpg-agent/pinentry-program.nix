{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf pkgs.stdenv.isLinux {
  services.gpg-agent.enable = true;
  services.gpg-agent.pinentry = {
    package = pkgs.pinentry-all;
    program = "pinentry-qt";
  };
  programs.gpg.enable = true;

  nmt.script = ''
    in="${config.systemd.user.sockets.gpg-agent.Socket.ListenStream}"
    if [[ $in != "%t/gnupg/S.gpg-agent" ]]
    then
      echo $in
      fail "gpg-agent socket directory not set to default value"
    fi

    configFile=home-files/.gnupg/gpg-agent.conf
    assertFileRegex $configFile "pinentry-program @pinentry-all@/bin/pinentry-qt"
  '';
}
