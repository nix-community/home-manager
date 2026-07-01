{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  programs.attic-client = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "attic";
      outPath = "@attic@";
    };
    settings = {
      default-server = "myserver";
      servers = {
        myserver = {
          endpoint = "https://myserver.org";
          token-file = "/run/secrets/attic-token";
        };
        myotherserver = {
          endpoint = "https://myotherserver.org";
          token-file = "/run/secrets/attic-token";
        };
      };
    };
    watchStore = lib.optionals isLinux [ "myserver:mycache" ];
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/attic/config.toml \
      ${builtins.toFile "expected.config" ''
        default-server = "myserver"

        [servers.myotherserver]
        endpoint = "https://myotherserver.org"
        token-file = "/run/secrets/attic-token"

        [servers.myserver]
        endpoint = "https://myserver.org"
        token-file = "/run/secrets/attic-token"
      ''}
  ''
  + lib.optionalString isLinux ''
    assertFileContent \
      home-files/.config/systemd/user/attic-watch-store--myserver-mycache.service \
      ${builtins.toFile "expected.service" ''
        [Install]
        WantedBy=default.target

        [Service]
        ExecStart=@attic@/bin/attic watch-store myserver:mycache
        Restart=always
        RestartSec=30

        [Unit]
        Description=Push new store paths to the attic cache myserver:mycache
      ''}
  '';
}
