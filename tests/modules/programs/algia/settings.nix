{
  lib,
  pkgs,
  config,
  ...
}:

{
  programs.algia = {
    enable = true;
    settings = {
      relays = {
        "wss =//relay-jp.nostr.wirednet.jp" = {
          read = true;
          write = true;
          search = false;
        };
      };
      privatekey = "nsecXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/algia/config.json
    assertFileContent home-files/.config/algia/config.json \
      ${./config.json}
  '';
}
