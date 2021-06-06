{ pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  path = if isDarwin then
    "Library/Application Support/rbw/config.json"
  else
    ".config/rbw/config.json";

  expected = pkgs.writeText "rbw-expected.json" ''
    {
      "base_url": null,
      "email": "name@example.com",
      "identity_url": null,
      "lock_timeout": 3600,
      "pinentry": "@pinentry-gtk2@/bin/pinentry"
    }
  '';
in {
  config = {
    programs.rbw = {
      enable = true;
      settings = { email = "name@example.com"; };
    };

    nixpkgs.overlays = [ (import ./overlay.nix) ];

    nmt.script = ''
      assertFileExists home-files/${path}
      assertFileContent home-files/${path} '${expected}'
    '';
  };
}
