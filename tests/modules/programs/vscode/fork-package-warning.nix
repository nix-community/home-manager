_package:

{
  pkgs,
  ...
}:

let
  vscodiumPackage = pkgs.writeScriptBin "vscodium" "" // {
    pname = "vscodium";
    version = "1.75.0";
  };
in

{
  programs.vscode = {
    enable = true;
    package = vscodiumPackage;
  };

  test.asserts.warnings.expected = [
    ''
      programs.vscode.package is set to a known VSCode fork (pname: "vscodium"),
      but programs.vscode now always writes to Visual Studio Code's paths
      (e.g. ~/.vscode, "Code/User"). Use programs.vscodium instead so that
      configuration is written to the fork's own paths.
    ''
  ];
}
