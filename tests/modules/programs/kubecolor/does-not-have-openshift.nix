{ config, ... }:

{
  programs.kubecolor = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "kubecolor";
      version = "0.4.0";
    };
    enableAlias = true;
  };
  programs.zsh = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "zsh";
      version = "5.9";
    };
  };

  nmt.script = ''
    assertFileNotRegex 'home-files/.zshrc' '^alias.* oc=.*'
  '';
}
