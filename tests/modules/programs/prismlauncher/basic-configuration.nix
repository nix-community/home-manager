{ config, lib, pkgs, ... }: {
  programs.prismlauncher = {
    enable = true;
    extraConfig = { General = { BackgroundCat = "kitteh"; }; };
    launcher = {
      instances = "/home/user/PrismLauncher/instances";
      mods = "/home/user/PrismLauncher/mods";
      icons = "/home/user/PrismLauncher/icons";
      downloads = "/home/user/PrismLauncher/downloads";
    };
    java = {
      maximumMemoryAllocation = 5678;
      path = "/example-path";
    };
    #     language = {
    #       language = "en_GB";
    #       useSystemLocales = true;
    #     };
  };

  test.stubs.prismlauncher = { };

  nmt.script = ''
    assertFileContains activate \
      '${config.xdg.dataHome}/PrismLauncher/prismlauncher.cfg'

    generated="$(grep -o '${config.xdg.dataHome}/PrismLauncher/prismlauncher.cfg' $TESTED/activate)"
    diff -u "$generated" ${./basic-configuration.cfg}

    echo "THIS TEST IS A TEMPORARY PLACEHOLDER! PLEASE WRITE THIS TEST!"
    exit 1
  '';
  # diff -u home-files/.local/share/PrismLauncher/prismlauncher.cfg ${./basic-configuration.cfg}
  # assertFileContent home-files/.local/share/PrismLauncher/prismlauncher.cfg ${./basic-configuration.cfg}
  # generated="$(grep -o '/nix/store/.*-prismlauncher.cfg' $TESTED/activate)"
  # diff -u "$generated" ${./basic-configuration.cfg}
}

