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
    "vscode-forks-${programName}-empty-profiles" = ./empty-profiles.nix;
    "vscode-forks-${programName}-extensions-mutable" = ./extensions-mutable.nix;
    "vscode-forks-${programName}-extensions-immutable" = ./extensions-immutable.nix;
    "vscode-forks-${programName}-profiles-immutable" = ./profiles-immutable.nix;
    "vscode-forks-${programName}-profiles-mutable" = ./profiles-mutable.nix;
  }
