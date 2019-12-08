{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.git = {
      enable = true;
      package = pkgs.gitMinimal;
      extraConfig = ''
        This can be anything.
      '';
      userEmail = "user@example.org";
      userName = "John Doe";
    };

    nmt.script = ''
      assertFileExists home-files/.config/git/config
      assertFileContent home-files/.config/git/config \
        ${./git-with-str-extra-config-expected.conf}
    '';
  };
}
