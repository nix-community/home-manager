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
    "vscode-forks-${programName}-settings-paths" = ./settings-paths.nix;
  }
