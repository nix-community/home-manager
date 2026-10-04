{ config, ... }:
{
  home.stateVersion = "21.11";
  programs.pet = {
    enable = false;
    enableMutableSnippets = true;
    package = null;
    snippets = [ { command = "echo declarative"; } ];
  };

  assertions = [
    {
      assertion = !(config.home.sessionVariables ? PET_CONFIG_DIR);
      message = "Disabled Pet must not set PET_CONFIG_DIR.";
    }
    {
      assertion = !(config.home.activation ? pet-user-snippets);
      message = "Disabled Pet must not register snippets activation.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/.config/pet"
  '';
}
