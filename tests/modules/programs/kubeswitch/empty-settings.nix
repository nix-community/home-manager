{
  programs.kubeswitch.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.kube/switch-config.yaml
  '';
}
