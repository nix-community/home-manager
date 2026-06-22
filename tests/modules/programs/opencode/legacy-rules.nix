{ lib, options, ... }:

{
  programs.opencode = {
    enable = true;
    rules = ./AGENTS.md;
  };

  test.asserts.warnings.expected = [
    "The option `programs.opencode.rules' defined in ${lib.showFiles options.programs.opencode.rules.files} has been renamed to `programs.opencode.context'."
  ];

  nmt.script = ''
    assertFileExists home-files/.config/opencode/AGENTS.md
    assertFileContent home-files/.config/opencode/AGENTS.md \
      ${./AGENTS.md}
  '';
}
