{ pkgs, ... }:
pkgs.writeTextFile {
  name = "fake-vscode";
  destination = "/lib/vscode/resources/app/product.json";
  text = builtins.toJSON {
    nameShort = "Code";
    dataFolderName = ".vscode";
  };
}
