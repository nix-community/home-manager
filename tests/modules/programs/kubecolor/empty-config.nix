{ pkgs, config, ... }:

let
  configDir =
    if pkgs.stdenv.isDarwin then "Library/Application Support" else ".config";
in {
  programs.kubecolor = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "kubecolor";
      version = "0.4.0";
    };
  };

  nmt.script = ''
    assertPathNotExists 'home-files/${configDir}/kube/color.yaml'
  '';
}
