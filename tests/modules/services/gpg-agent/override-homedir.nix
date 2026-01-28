{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv) isDarwin;
in
{
  test.unstubs = [
    (_: _: {
      runCommandCC = (
        _: _: _:
        "@gpg-agent-wrapper@"
      );
    })
  ];

  services.gpg-agent.enable = true;
  programs.gpg = {
    enable = true;
    homedir = "/path/to/hash";
    package = config.lib.test.mkStubPackage { outPath = "@gpg@"; };
  };

  nmt.script =
    if isDarwin then
      ''
        serviceFile=LaunchAgents/org.nix-community.home.gpg-agent.plist
        assertFileExists "$serviceFile"
        assertFileContent "$serviceFile" ${./expected-agent.plist}
      ''
    else
      ''
        in="${config.systemd.user.sockets.gpg-agent.Socket.ListenStream}"
        if [[ $in != "%t/gnupg/d.wp4h7ks5zxy4dodqadgpbbpz/S.gpg-agent" ]]
        then
          echo $in
          fail "gpg-agent socket directory is malformed"
        fi
      '';
}
