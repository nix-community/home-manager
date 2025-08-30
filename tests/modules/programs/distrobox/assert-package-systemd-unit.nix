{
  programs.distrobox = {
    enable = true;
    package = null;
    enableSystemdUnit = true;
    containers = {
      python-project = {
        image = "fedora:40";
        additional_packages = "python3 git";
        init_hooks = "pip3 install numpy pandas torch torchvision";
      };
    };
  };

  test.asserts.assertions.expected = [
    "Cannot set `programs.distrobox.enableSystemdUnit` if `programs.distrobox.package` is set to null."
  ];
}
