{ config, ... }: {
  programs = {
    mise = {
      package = config.lib.test.mkStubPackage { name = "mise"; };
      enable = true;
      enableNushellIntegration = true;
    };

    nushell.enable = true;
  };

  nmt.script = ''
    assertFileContains home-files/.config/nushell/env.nu \
      '
      let mise_path = $nu.default-config-dir | path join mise.nu
      ^mise activate nu | save $mise_path --force
      '
    assertFileContains home-files/.config/nushell/config.nu \
      'use ($nu.default-config-dir | path join mise.nu)'
  '';
}
