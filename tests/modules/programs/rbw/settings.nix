{ pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  path = if isDarwin then
    "Library/Application Support/rbw/config.json"
  else
    ".config/rbw/config.json";

  expected = pkgs.writeText "rbw-expected.json" ''
    {
      "base_url": "bitwarden.example.com",
      "email": "name@example.com",
      "identity_url": "identity.example.com",
      "lock_timeout": 300,
      "pinentry": "@pinentry-gnome3@/bin/pinentry"
    }
  '';
in {
  imports = [ ./rbw-stubs.nix ];

  programs.rbw = {
    enable = true;
    settings = {
      email = "name@example.com";
      base_url = "bitwarden.example.com";
      identity_url = "identity.example.com";
      lock_timeout = 300;
      pinentry = "gnome3";
    };
  };

  nmt.script = ''
    assertFileExists home-files/${path}
    assertFileContent home-files/${path} '${expected}'
  '';
}
