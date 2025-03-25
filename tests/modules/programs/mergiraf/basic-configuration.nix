{ config, lib, ... }:

{
  programs.git.enable = true;
  programs.mergiraf.enable = true;

  nmt.script = ''
    assertFileContent "home-files/.config/git/config" ${./mergiraf-git.conf}
    assertFileContent "home-files/.config/git/attributes" ${
      ./mergiraf-git-attributes.conf
    }
  '';
}
