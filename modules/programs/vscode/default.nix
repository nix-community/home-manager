{ config, lib, ... }:
let
  modulePath = [
    "programs"
    "vscode"
  ];

  mkVscodeModule = import ./mkVscodeModule.nix;

  # Map of known VSCode fork pnames to their dedicated module path.
  forkModules = {
    vscodium = "programs.vscodium";
    code-cursor = "programs.cursor";
    windsurf = "programs.windsurf";
    kiro = "programs.kiro";
    antigravity = "programs.antigravity";
  };
in
{
  imports = [
    (mkVscodeModule {
      inherit modulePath;
      name = "Visual Studio Code";
      packageName = "vscode";
      nameShort = "Code";
      dataFolderName = ".vscode";
    })

    ./haskell.nix

    (lib.mkChangedOptionModule
      [
        "programs"
        "vscode"
        "immutableExtensionsDir"
      ]
      [ "programs" "vscode" "mutableExtensionsDir" ]
      (config: !config.programs.vscode.immutableExtensionsDir)
    )

    (lib.mkRemovedOptionModule [ "programs" "vscode" "pname" ] ''
      The programs.vscode.pname option has been removed. Each VSCode fork
      now has its own dedicated module (programs.vscodium, programs.cursor,
      programs.windsurf, programs.kiro, programs.antigravity). Please switch
      to the module corresponding to your fork instead of setting
      programs.vscode.package to a fork package.
    '')
  ]
  ++
    map
      (
        v:
        lib.mkRenamedOptionModule
          [ "programs" "vscode" v ]
          [
            "programs"
            "vscode"
            "profiles"
            "default"
            v
          ]
      )
      [
        "enableUpdateCheck"
        "enableExtensionUpdateCheck"
        "userSettings"
        "userTasks"
        "userMcp"
        "keybindings"
        "extensions"
        "languageSnippets"
        "globalSnippets"
      ];

  config = lib.mkIf config.programs.vscode.enable {
    warnings =
      let
        pkg = config.programs.vscode.package;
        pname = if pkg != null then pkg.pname or null else null;
        forkModule = if pname != null then forkModules.${pname} or null else null;
      in
      lib.optional (forkModule != null) ''
        programs.vscode.package is set to a known VSCode fork (pname: "${pname}"),
        but programs.vscode now always writes to Visual Studio Code's paths
        (e.g. ~/.vscode, "Code/User"). Use ${forkModule} instead so that
        configuration is written to the fork's own paths.
      '';
  };
}
