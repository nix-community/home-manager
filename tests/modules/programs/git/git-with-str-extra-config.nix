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

    test.asserts.warnings.expected = [''
      Using programs.git.extraConfig as a string option is
      deprecated and will be removed in the future. Please
      change to using it as an attribute set instead.
    ''];

    nmt.script = ''
      assertFileExists home-files/.config/git/config
      assertFileContent home-files/.config/git/config \
        ${./git-with-str-extra-config-expected.conf}
    '';
  };
}
