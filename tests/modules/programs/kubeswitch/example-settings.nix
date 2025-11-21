{
  programs.kubeswitch = {
    enable = true;

    settings = {
      kind = "SwitchConfig";
      version = "v1alpha1";
      kubeconfigName = "*.myconfig";
      kubeconfigStores = [
        {
          kind = "filesystem";
          kubeconfigName = "*.myconfig";
          paths = [
            "~/.kube/my-other-kubeconfigs/"
          ];
        }
      ];
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.kube/switch-config.yaml \
      ${builtins.toFile "example-settings-expected.yaml" ''
        kind: SwitchConfig
        kubeconfigName: '*.myconfig'
        kubeconfigStores:
        - kind: filesystem
          kubeconfigName: '*.myconfig'
          paths:
          - ~/.kube/my-other-kubeconfigs/
        version: v1alpha1
      ''}
  '';
}
