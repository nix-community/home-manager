{ lib, pkgs, ... }:
let
  inherit (lib.hm.systemd) escapeExecArg escapeExecArgs;
  contextString = builtins.toFile "systemd-argument" "argument";
in
{
  assertions = [
    {
      assertion = escapeExecArgs [ ] == "";
      message = "An empty argument list must produce no arguments.";
    }
    {
      assertion =
        escapeExecArgs [
          42
          1.5
        ] == ''"42" "1.500000"'';
      message = "Numeric arguments must be converted to strings.";
    }
    {
      assertion = escapeExecArg ./default.nix == builtins.toJSON "${./default.nix}";
      message = "Path arguments must retain their store references.";
    }
    {
      assertion = escapeExecArg pkgs.emptyDirectory == builtins.toJSON "${pkgs.emptyDirectory}";
      message = "Derivation arguments must use their output paths.";
    }
    {
      assertion = builtins.getContext (escapeExecArg contextString) == builtins.getContext contextString;
      message = "Escaping must preserve string context.";
    }
    {
      assertion = lib.all (arg: !(builtins.tryEval (escapeExecArg arg)).success) [
        null
        true
        [ ]
        { }
      ];
      message = "Unsupported argument types must be rejected.";
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
