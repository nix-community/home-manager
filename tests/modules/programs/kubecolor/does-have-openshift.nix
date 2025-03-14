{ config, pkgs, ... }:

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
  nixpkgs.overlays = [
    (self: super: rec {
      openshift = config.lib.test.mkStubPackage {
        name = "openshift";
        version = "4.16.0";
      };
    })
  ];
  home.packages = [ pkgs.openshift ];

  nmt.script = ''
    assertFileRegex 'home-files/.zshrc' '^alias.* oc=.*'
  '';
}

