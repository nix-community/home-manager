{ lib, pkgs, ... }:
let
  inherit (lib.hm.strings) escapeSystemdExecArg escapeSystemdExecArgs;
  contextString = builtins.toFile "systemd-argument" "argument";
in
{
  assertions = [
    {
      assertion = escapeSystemdExecArgs [ ] == "";
      message = "Empty lists must produce no arguments.";
    }
    {
      assertion =
        escapeSystemdExecArgs [
          42
          1.5
        ] == ''"42" "1.500000"'';
      message = "Numbers must become strings.";
    }
    {
      assertion = escapeSystemdExecArg ./default.nix == builtins.toJSON "${./default.nix}";
      message = "Paths must retain store references.";
    }
    {
      assertion = escapeSystemdExecArg pkgs.emptyDirectory == builtins.toJSON "${pkgs.emptyDirectory}";
      message = "Derivations must use output paths.";
    }
    {
      assertion =
        builtins.getContext (escapeSystemdExecArg contextString) == builtins.getContext contextString;
      message = "String context must be preserved.";
    }
    {
      assertion = lib.all (arg: !(builtins.tryEval (escapeSystemdExecArg arg)).success) [
        null
        true
        [ ]
        { }
      ];
      message = "Unsupported types must be rejected.";
    }
  ];

  home.file."escaped-args".text =
    escapeSystemdExecArgs [
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
