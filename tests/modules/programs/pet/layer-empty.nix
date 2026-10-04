{ config, ... }:
{
  home.stateVersion = "21.11";
  programs.pet = {
    enable = true;
    enableMutableSnippets = true;
    package = null;
  };

  assertions = [
    {
      assertion = config.home.sessionVariables.PET_CONFIG_DIR == "${config.xdg.configHome}/pet";
      message = "Empty mutable Pet snippets must still set PET_CONFIG_DIR.";
    }
    {
      assertion = config.home.activation.pet-user-snippets.after == [ "linkGeneration" ];
      message = "Empty mutable Pet snippets must activate after linkGeneration.";
    }
    {
      assertion = !(config.programs.pet.settings.General ? snippetdirs);
      message = "Empty Pet snippets must not add a declarative snippet directory.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/.config/pet/home-manager-snippets"
    assertPathNotExists "home-files/.config/pet/snippet.toml"
    assertFileContent "home-files/.config/pet/config.toml" ${./empty-config.toml}
    assertFileContains activate '${config.xdg.configHome}/pet/snippet.toml'
    seed="$(grep -o '/nix/store/[^ ]*-pet-empty-snippets' "$TESTED/activate")" \
      || fail "Pet empty snippets input is missing from activation"
    assertFileContent "$seed" ${./empty-snippets.toml}
  '';
}
