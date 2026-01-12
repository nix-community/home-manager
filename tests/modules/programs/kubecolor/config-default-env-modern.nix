{ pkgs, config, ... }:

let
  configDir = if pkgs.stdenv.isDarwin then "Library/Application Support/kube" else ".kube";
in
{
  programs.kubecolor = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "kubecolor";
      version = "0.4.0";
    };
    settings = {
      kubectl = "kubectl";
    };
  };

  nmt.script = ''
    if [[ "${config.home.sessionVariables.KUBECOLOR_CONFIG}" != "${configDir}/color.yaml" ]]; then
      fail "Expected KUBECOLOR_CONFIG to be '${configDir}/color.yaml', got '${config.home.sessionVariables.KUBECOLOR_CONFIG}'"
    fi
  '';
}
