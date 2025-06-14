{ realPkgs, ... }:
{
  test.unstubs = [
    (_: _: { inherit (realPkgs) timewarrior; })
  ];

  programs.taskwarrior = {
    enable = true;
    package = realPkgs.taskwarrior3;
  };

  programs.timewarrior = {
    enable = true;
    taskwarrior.enable = true;
  };

  nmt.script = ''
    assertLinkExists home-files/.local/share/task/hooks/on-modify.timewarrior
    assertFileIsExecutable home-files/.local/share/task/hooks/on-modify.timewarrior
  '';
}
