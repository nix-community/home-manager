{ pkgs, ... }:

{
  programs.sapling = {
    enable = true;
    userName = "John Doe";
    userEmail = "johndoe@example.com";
  };

  test.stubs.sapling = { };

  nmt.script = let
    configfile = if pkgs.stdenv.isDarwin then
      "Library/Preferences/sapling/sapling.conf"
    else
      ".config/sapling/sapling.conf";

    expected = builtins.toFile "sapling.conf" ''
      [ui]
      username=John Doe <johndoe@example.com>
    '';
  in ''
    assertFileExists home-files/${configfile}
    assertFileContent home-files/${configfile} ${expected}
  '';
}
