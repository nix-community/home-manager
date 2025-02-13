{
  programs = {
    zsh.enable = true;

    powerline-go = {
      enable = true;
      newline = true;
      modules = [ "nix-shell" ];
      modulesRight = [ "git" ];
      pathAliases = { "\\~/project/foo" = "prj-foo"; };
      settings = {
        ignore-repos = [ "/home/me/project1" "/home/me/project2" ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval'
    assertFileContains \
      home-files/.zshrc \
      '/bin/powerline-go -error $? -shell zsh -eval -modules nix-shell -modules-right git -newline -path-aliases \~/project/foo=prj-foo -ignore-repos /home/me/project1,/home/me/project2'
  '';
}
