# Test that keybdinings.json is created correctly.
{ config, lib, pkgs, ... }:

with lib;

let
  bindings = [
    {
      key = "ctrl+c";
      command = "editor.action.clipboardCopyAction";
      when = "textInputFocus && false";
    }
    {
      key = "ctrl+c";
      command = "deleteFile";
      when = "";
    }
    {
      key = "d";
      command = "deleteFile";
      when = "explorerViewletVisible";
    }
  ];

  targetPath = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/Code/User/keybindings.json"
  else
    ".config/Code/User/keybindings.json";

  expectedJson = pkgs.writeText "expected.json" (builtins.toJSON bindings);
in {
  config = {
    programs.vscode = {
      enable = true;
      keybindings = bindings;
    };

    nixpkgs.overlays = [
      (self: super: {
        vscode = pkgs.runCommandLocal "vscode" { pname = "vscode"; } ''
          mkdir -p $out/bin
          touch $out/bin/code
          chmod +x $out/bin/code;
        '';
      })
    ];

    nmt.script = ''
      assertFileExists "home-files/${targetPath}"
      assertFileContent "home-files/${targetPath}" "${expectedJson}"
    '';
  };
}
