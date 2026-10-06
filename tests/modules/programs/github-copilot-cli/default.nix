{
  github-copilot-cli-cleanup-disabled = import ./settings-wiring.nix "cleanup-disabled";
  github-copilot-cli-cleanup-redirected = import ./settings-wiring.nix "cleanup-redirected";
  github-copilot-cli-disabled = import ./settings-wiring.nix "disabled";
  github-copilot-cli-config = ./config.nix;
  github-copilot-cli-directories = ./directories.nix;
  github-copilot-cli-lsp = ./lsp.nix;
  github-copilot-cli-mcp = ./mcp.nix;
  github-copilot-cli-mcp-integration = ./mcp-integration.nix;
  github-copilot-cli-mutable-empty-settings = import ./settings-wiring.nix "mutable-empty";
  github-copilot-cli-mutable-settings = ./mutable-settings.nix;
  github-copilot-cli-path-not-directory = ./path-not-directory.nix;
  github-copilot-cli-store-path-dir = ./store-path-dir.nix;
  github-copilot-cli-store-path-skills = ./store-path-skills.nix;
  github-copilot-cli-trusted-folders = ./trusted-folders.nix;
  github-copilot-cli-xdg-config-dir = ./xdg-config-dir.nix;
}
