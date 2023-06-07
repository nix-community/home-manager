{ pkgs, config, ... }: {
  config = {
    programs.ripgrep = {
      enable = true;
      package = config.lib.test.mkStubPackage { name = "ripgrep"; };
      arguments = [
        "--max-columns-preview"
        "--colors=line:style:bold"
        "--no-require-git"
      ];
    };

    nmt.script = ''
      assertFileExists home-files/.config/ripgrep/ripgreprc
      assertFileContent home-files/.config/ripgrep/ripgreprc ${
        pkgs.writeText "ripgrep.expected" ''
          --max-columns-preview
          --colors=line:style:bold
          --no-require-git
        ''
      }
    '';
  };
}
