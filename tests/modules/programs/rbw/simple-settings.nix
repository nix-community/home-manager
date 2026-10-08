{ pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  path =
    if isDarwin then "Library/Application Support/rbw/config.json" else ".config/rbw/config.json";

  expected = builtins.toFile "rbw-expected.json" ''
    {
      "email": "name@example.com",
      "lock_timeout": 3600
    }
  '';
in
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "name@example.com";
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${path}"
    assertFileContent "home-files/${path}" '${expected}'
  '';
}
