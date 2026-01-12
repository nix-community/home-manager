{ config, ... }:

{
  xdg.enable = true;
  home.preferXdgDirectories = true;

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
    if [[ "${config.home.sessionVariables.KUBECOLOR_CONFIG}" != "/home/hm-user/.config/kube/color.yaml" ]]; then
      fail "Expected KUBECOLOR_CONFIG to be '/home/hm-user/.config/kube/color.yaml', got '${config.home.sessionVariables.KUBECOLOR_CONFIG}'"
    fi
  '';
}
