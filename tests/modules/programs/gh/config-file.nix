{ config, lib, pkgs, ... }:

{
  config = {
    programs.gh = {
      enable = true;
      settings.aliases = { co = "pr checkout"; };
      settings.editor = "vim";
    };

    test.stubs.gh = { };

    nmt.script = ''
      assertFileExists home-files/.config/gh/config.yml
      assertFileContent home-files/.config/gh/config.yml ${
        builtins.toFile "config-file.yml" ''
          aliases:
            co: pr checkout
          editor: vim
          git_protocol: https
        ''
      }
    '';
  };
}
