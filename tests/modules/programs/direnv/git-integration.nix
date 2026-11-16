{ config, ... }:
{
  programs = {
    direnv = {
      enable = true;
      enableGitIntegration = true;
      nix-direnv.package = config.lib.test.mkStubPackage {
        buildScript = ''
          mkdir -p $out/share/nix-direnv/
          touch $out/share/nix-direnv/direnvrc
        '';
      };
    };

    git.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/ignore
    assertFileContains home-files/.config/git/ignore ".direnv/"
  '';
}
