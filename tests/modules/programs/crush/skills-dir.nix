{ config, ... }:

{
  programs.crush = {
    enable = true;
    skillsDir = ./skills;
  };

  nmt.script = ''
    assertDirectoryExists home-files/.config/crush/skills
    assertLinkExists home-files/.config/crush/skills
  '';
}
