{
  programName,
  packageName ? programName,
  configDirName ? programName,
  ...
}:
builtins.mapAttrs
  (
    test: module:
    import module {
      inherit packageName configDirName;
      modulePath = [
        "programs"
        programName
      ];
    }
  )
  {
    "vscode-forks-${programName}-keybindings-immutable" = ./keybindings-immutable.nix;
    "vscode-forks-${programName}-keybindings-mutable" = ./keybindings-mutable.nix;
    "vscode-forks-${programName}-mcp-immutable" = ./mcp-immutable.nix;
    "vscode-forks-${programName}-mcp-mutable" = ./mcp-mutable.nix;
    "vscode-forks-${programName}-settings-immutable" = ./settings-immutable.nix;
    "vscode-forks-${programName}-settings-mutable" = ./settings-mutable.nix;
    "vscode-forks-${programName}-tasks-immutable" = ./tasks-immutable.nix;
    "vscode-forks-${programName}-tasks-mutable" = ./tasks-mutable.nix;
  }
