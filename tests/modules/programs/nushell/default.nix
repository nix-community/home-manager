{
  nushell-example-settings = ./example-settings.nix;
  nushell-config-dir = ./config-dir.nix;
  nushell-session-variables = ./session-variables.nix;
  nushell-session-variables-legacy = import ./session-variables-state-version.nix {
    stateVersion = "26.05";
  };
  nushell-session-variables-current = import ./session-variables-state-version.nix {
    stateVersion = "26.11";
  };
  nushell-session-variables-opt-in = import ./session-variables-state-version.nix {
    stateVersion = "26.05";
    loadSessionVariables = true;
  };
  nushell-session-variables-opt-out = import ./session-variables-state-version.nix {
    stateVersion = "26.11";
    loadSessionVariables = false;
  };
}
