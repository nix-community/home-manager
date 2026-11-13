{ config, ... }:
let
  configHome = "${config.xdg.configHome}/pet";
  layerDir = "${configHome}/home-manager-snippets";
in
{
  home.stateVersion = "21.11";
  xdg.configHome = "${config.home.homeDirectory}/.custom";
  programs.pet = {
    enable = true;
    mutableSnippets = true;
    package = null;
    snippets = [
      {
        description = "declarative";
        command = "echo declarative";
      }
    ];
    settings.General = {
      snippetdirs = [ "${configHome}/other-snippets" ];
      snippetfile = "${configHome}/writable.toml";
    };
  };

  assertions = [
    {
      assertion = config.home.sessionVariables.PET_CONFIG_DIR == configHome;
      message = "Mutable Pet snippets must use the configured PET_CONFIG_DIR.";
    }
    {
      assertion = config.home.activation.pet-user-snippets.after == [ "linkGeneration" ];
      message = "Mutable Pet snippets must activate after linkGeneration.";
    }
    {
      assertion =
        config.programs.pet.settings.General.snippetdirs == [
          layerDir
          "${configHome}/other-snippets"
        ];
      message = "Pet must prepend its declarative layer and retain user snippet directories.";
    }
  ];

  nmt.script = ''
    assertFileContent "home-files/.custom/pet/home-manager-snippets/snippet.toml" ${./layer-snippet.toml}
    assertPathNotExists "home-files/.custom/pet/snippet.toml"
    assertFileContent "home-files/.custom/pet/config.toml" ${./layer-custom-config.toml}
    assertFileContains activate '${config.home.homeDirectory}/.custom/pet/writable.toml'
    seed="$(grep -o '/nix/store/[^ ]*-pet-empty-snippets' "$TESTED/activate")" \
      || fail "Pet empty snippets input is missing from activation"
    assertFileContent "$seed" ${./empty-snippets.toml}
  '';
}
