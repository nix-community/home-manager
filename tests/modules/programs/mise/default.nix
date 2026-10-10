{
  mise-default-settings = ./default-settings.nix;
  mise-custom-settings = ./custom-settings.nix;
  mise-custom-settings-renamed = ./custom-settings-renamed.nix;
  mise-mutable-config = ./mutable-config.nix;
  mise-bash-integration = ./bash-integration.nix;
  mise-zsh-integration = ./zsh-integration.nix;
  mise-fish-integration = ./fish-integration.nix;
  mise-nushell-integration = import ./nushell-integration.nix { };
  mise-nushell-integration-legacy = import ./nushell-integration.nix {
    miseVersion = "2026.8.16";
  };
}
