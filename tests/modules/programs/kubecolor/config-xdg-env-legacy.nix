{ config, ... }:

{
  xdg.enable = true;
  home.preferXdgDirectories = true;

  programs.kubecolor = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "kubecolor";
      version = "0.3.0";
    };
    settings = {
      kubectl = "kubectl";
    };
  };

  nmt.script = ''
    if [[ "${config.home.sessionVariables.KUBECOLOR_CONFIG}" != "/home/hm-user/.config/kube/" ]]; then
      fail "Expected KUBECOLOR_CONFIG to be '/home/hm-user/.config/kube/', got '${config.home.sessionVariables.KUBECOLOR_CONFIG}'"
    fi
  '';
}
