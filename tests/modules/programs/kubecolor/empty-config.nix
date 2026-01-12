{ config, ... }:

{
  programs.kubecolor = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "kubecolor";
      version = "0.4.0";
    };
  };

  nmt.script = ''
    assertPathNotExists 'home-files/.kube/color.yaml'
    assertPathNotExists 'home-files/.config/kubecolor.yaml'
  '';
}
