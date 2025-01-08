{ config, ... }:

{
  config = {
    programs.helm.enable = true;

    test.stubs.kubernetes-helm = { };

    nmt.script = ''
      assertPathNotExists home-files/Library/helm
      assertPathNotExists ${config.xdg.dataHome}/helm
    '';
  };
}
