{
  pkgs,
  lib,
  options,
  ...
}:

let
  renamedWarning =
    name:
    "The option `programs.gemini-cli.${name}' defined in ${
      lib.showFiles (
        lib.getAttrFromPath [
          "programs"
          "gemini-cli"
          name
          "files"
        ] options
      )
    } has been renamed to `programs.antigravity-cli.${name}'.";
in
{
  programs.gemini-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "gemini-cli" "";
    context = {
      # Test inline content
      GEMINI = ''
        # Global Context

        You are a helpful AI assistant for software development.

        ## Coding Standards

        - Follow consistent code style
        - Write clear comments
        - Test your changes
      '';
      # Test file path
      AGENTS = ./context.md;
      # Test another inline content
      CONTEXT = ''
        Additional context for specialized tasks.
      '';
    };
    settings = {
      context.fileName = [
        "AGENTS.md"
        "CONTEXT.md"
        "GEMINI.md"
      ];
    };
  };
  test.asserts.warnings.expected = map renamedWarning [
    "settings"
    "package"
    "enable"
    "context"
  ];

  nmt.script = ''
    assertFileExists home-files/.gemini/GEMINI.md
    assertFileContent home-files/.gemini/GEMINI.md \
      ${./context-inline.md}

    assertFileExists home-files/.gemini/AGENTS.md
    assertFileContent home-files/.gemini/AGENTS.md \
      ${./context.md}

    assertFileExists home-files/.gemini/CONTEXT.md
    assertFileContent home-files/.gemini/CONTEXT.md \
      ${./context-additional.md}

    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      "GEMINI_MODEL"
  '';
}
