{
  vscode-keybindings = ./keybindings.nix;
  vscode-tasks = ./tasks.nix;
  vscode-mcp = ./mcp.nix;
  vscode-update-checks = ./update-checks.nix;
  vscode-snippets = ./snippets.nix;
}
// (import ./tests.nix {
  programName = "vscode";
})
// (import ./tests.nix {
  programName = "cursor";
  packageName = "code-cursor";
})
