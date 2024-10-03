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
    settings = {
      kubectl = "kubectl";
      preset = "dark";
      objFreshThreshold = 0;
      paging = "auto";
      pager = "less";
    };
  };

  nmt.script = ''
    assertFileExists 'home-files/${configDir}/kube/color.yaml'
    assertFileContent 'home-files/${configDir}/kube/color.yaml' \
      ${
        builtins.toFile "expected.yaml" ''
          kubectl: kubectl
          objFreshThreshold: 0
          pager: less
          paging: auto
          preset: dark
        ''
      }
  '';
}
