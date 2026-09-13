{ lib, pkgs, ... }:
let
  inherit (lib.hm.systemd) escapeExecArg escapeExecArgs;
  contextString = builtins.toFile "systemd-argument" "argument";
in
{
  assertions = [
    {
      assertion = escapeExecArgs [ ] == "";
      message = "Empty lists must produce no arguments.";
    }
    {
      assertion =
        escapeExecArgs [
          42
          1.5
        ] == ''"42" "1.500000"'';
      message = "Numbers must become strings.";
    }
    {
      assertion = escapeExecArg ./default.nix == builtins.toJSON "${./default.nix}";
      message = "Paths must retain store references.";
    }
    {
      assertion = escapeExecArg pkgs.emptyDirectory == builtins.toJSON "${pkgs.emptyDirectory}";
      message = "Derivations must use output paths.";
    }
    {
      assertion = builtins.getContext (escapeExecArg contextString) == builtins.getContext contextString;
      message = "String context must be preserved.";
    }
    {
      assertion = lib.all (arg: !(builtins.tryEval (escapeExecArg arg)).success) [
        null
        true
        [ ]
        { }
      ];
      message = "Unsupported types must be rejected.";
    }
  ];

  home.file."escaped-args".text =
    escapeExecArgs [
      "plain"
      ""
      "two words"
      "1\nday"
      "tab\treturn\r"
      "quote\" apostrophe' backslash\\"
      "%h"
      "$HOME"
      "\${HOME}"
      ";"
      "café"
    ]
    + "\n";

  nmt.script = ''
    assertFileContent home-files/escaped-args ${./escaped-args.txt}
  '';
}
