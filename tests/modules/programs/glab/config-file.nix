{ config, lib, pkgs, ... }:

{
  config = {
    programs.glab = {
      enable = true;
      settings.git_protocol = "ssh";
      settings.editor = "vim";
    };

    test.stubs.glab = { };

    nmt.script = ''
      assertFileExists home-files/.config/glab-cli/config.yml
      assertFileContent home-files/.config/glab-cli/config.yml ${
        builtins.toFile "config-file.yml" ''
          git_protocol: ssh
          editor: vim
        ''
      }
    '';
  };
}
