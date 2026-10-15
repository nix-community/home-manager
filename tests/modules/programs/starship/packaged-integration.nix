{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs = {
    bash.enable = true;
    zsh.enable = true;
    fish.enable = true;
    nushell.enable = true;
    starship = {
      enable = true;
      enableTransience = true;
      extraPackages = [ pkgs.hello ];
    };
  };

  test.stubs.starship = {
    name = "starship";
    outPath = null;
    version = "1";
    extraAttrs.passthru.shellIntegration = ./shell-integration;
    buildScript = ''
      mkdir -p "$out/bin"
      printf '#!/bin/sh\nexit 97\n' > "$out/bin/starship"
      chmod +x "$out/bin/starship"
    '';
  };

  assertions = [
    {
      assertion =
        lib.hasInfix "/starship.fish" config.programs.fish.interactiveShellInit
        && !(lib.hasInfix "/starship.fish" config.programs.fish.shellInitLast);
      message = "Packaged Starship integration must remain in the interactive fish initialization phase.";
    }
  ];

  nmt.script = ''
    assertFileContains home-files/.bashrc '/starship.bash'
    assertFileContains home-files/.zshrc '/starship.zsh'
    assertFileContains home-files/.config/fish/config.fish '/starship.fish'
    assertFileContains home-files/.config/fish/config.fish 'enable_transience'
    assertFileRegex home-files/.config/nushell/config.nu 'use .*/starship.nu'

    integrationDir=$(sed -n 's|^use \(.*\)/starship.nu$|\1|p' "$TESTED/home-files/.config/nushell/config.nu")
    for shell in bash zsh fish nu; do
      assertFileContent "$(normalizeStorePaths "$integrationDir/starship.$shell")" \
        ${./shell-integration/expected-executable}
    done
  '';
}
