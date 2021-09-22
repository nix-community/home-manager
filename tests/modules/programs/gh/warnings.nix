{ config, options, lib, pkgs, ... }:

{
  config = {
    programs.gh = {
      enable = true;
      aliases = { co = "pr checkout"; };
      editor = "vim";
    };

    test.stubs.gh = { };

    test.asserts.warnings.expected = [
      "The option `programs.gh.editor' defined in ${
        lib.showFiles options.programs.gh.editor.files
      } has been renamed to `programs.gh.settings.editor'."
      "The option `programs.gh.aliases' defined in ${
        lib.showFiles options.programs.gh.aliases.files
      } has been renamed to `programs.gh.settings.aliases'."
    ];
    test.asserts.warnings.enable = true;

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
