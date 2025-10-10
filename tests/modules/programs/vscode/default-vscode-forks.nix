{
  programName,
  packageName ? programName,
  ...
}:
builtins.mapAttrs
  (
    test: module:
    import module {
      inherit programName packageName;

      modulePath = [
        "programs"
        programName
      ];
    }
  )
  {
    "${programName}-vscode-forks-empty-profiles" = ./empty-profiles.nix;
    "${programName}-vscode-forks-extensions-mutable" = ./extensions-mutable.nix;
    "${programName}-vscode-forks-extensions-mutable-no-json-support" =
      ./extensions-mutable-no-json-support.nix;
    "${programName}-vscode-forks-extensions-immutable-unsupported" =
      ./extensions-immutable-unsupported.nix;
    "${programName}-vscode-forks-extensions-immutable" = ./extensions-immutable.nix;
    "${programName}-vscode-forks-profiles-immutable" = ./profiles-immutable.nix;
    "${programName}-vscode-forks-profiles-mutable" = ./profiles-mutable.nix;
  }
