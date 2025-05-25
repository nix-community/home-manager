{
  programs.git.enable = true;
  programs.mergiraf.enable = true;

  nmt.script = ''
    assertFileContent "home-files/.config/git/config" ${./mergiraf-git.conf}
    assertFileExists "home-files/.config/git/attributes"
  '';
}
