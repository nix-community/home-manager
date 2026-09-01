{ pkgs, ... }:
let
  derivation-hook = pkgs.writeShellScript "derivation-hook" ''
    echo "About to edit file: $1"
  '';
in
{
  programs.claude-code = {
    enable = true;
    hooks = {
      inline-hook = ''
        #!/usr/bin/env bash
        echo "About to edit file: $1"
      '';
      test-hook = ./hooks/test-hook;
      inherit derivation-hook;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/hooks/inline-hook
    assertFileIsExecutable home-files/.claude/hooks/inline-hook

    assertFileExists home-files/.claude/hooks/test-hook
    assertFileIsExecutable home-files/.claude/hooks/test-hook
    assertFileContent home-files/.claude/hooks/test-hook \
      ${./hooks/test-hook}

    assertFileExists home-files/.claude/hooks/derivation-hook
    assertFileIsExecutable home-files/.claude/hooks/derivation-hook
    assertFileContent home-files/.claude/hooks/derivation-hook \
      ${derivation-hook}
  '';
}
