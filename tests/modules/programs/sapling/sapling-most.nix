{ pkgs, ... }:

{
  programs.sapling = {
    enable = true;
    userName = "John Doe";
    userEmail = "johndoe@example.com";
    aliases = {
      cm = "commit";
      d = "diff --exclude=*.lock";
      s = "status";
      view = "!$HG config paths.default | xargs open";
    };
    extraConfig = {
      pager.pager = "delta";
      gpg.key = "not-an-actual-key";
    };
  };

  test.stubs.sapling = { };

  nmt.script = let
    configfile = if pkgs.stdenv.isDarwin then
      "Library/Preferences/sapling/sapling.conf"
    else
      ".config/sapling/sapling.conf";

    expected = builtins.toFile "sapling.conf" ''
      [alias]
      cm=commit
      d=diff --exclude=*.lock
      s=status
      view=!$HG config paths.default | xargs open

      [gpg]
      key=not-an-actual-key

      [pager]
      pager=delta

      [ui]
      username=John Doe <johndoe@example.com>
    '';
  in ''
    assertFileExists home-files/${configfile}
    assertFileContent home-files/${configfile} ${expected}
  '';
}
