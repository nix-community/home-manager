{ pkgs, config, lib, ... }:

let cfg = config.programs.vscode.haskell;

in with lib; {
  imports = [
    (lib.mkRemovedOptionModule [ "hie" "enable" ] ''
      Haskell support for VSCode now uses the Haskell Language Server, enabled automatically.
    '')
    (lib.mkRemovedOptionModule [ "hie" "path" ] ''
      Haskell support for VSCode now uses the Haskell Language Server.
      Use programs.vscode.haskell.hlsPackage to change the HLS executable.
    '')
  ];

  options.programs.vscode.haskell = {
    enable = mkEnableOption "Haskell integration for Visual Studio Code";

    useGhcup = mkEnableOption "using GHCup for the Haskell integration";

    hlsPackage = mkPackageOption pkgs "Haskell language server" {
      default = [ "haskell-language-server" ];
    };

    ghcupPackage =
      mkPackageOption pkgs "GHCup" { default = [ "haskellPackages" "ghcup" ]; };
  };

  config = mkIf cfg.enable {
    programs.vscode.userSettings = mkMerge [
      (mkIf cfg.useGhcup {
        "haskell.ghcupExecutablePath" = cfg.ghcupPackage;
        "haskell.manageHLS" = "GHCup";
      })

      (mkIf (!cfg.useGhcup) {
        "haskell.serverExecutablePath" = cfg.hlsPackage + "/bin";
      })
    ];

    programs.vscode.extensions = with pkgs.vscode-extensions; [
      haskell.haskell
      justusadam.language-haskell
    ];
  };
}
