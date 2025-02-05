{
  programs = {
    bash.enable = true;

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
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval'
    assertFileContains \
      home-files/.bashrc \
      '/bin/powerline-go -error $old_exit_status -shell bash -eval -modules nix-shell -modules-right git -newline -path-aliases \~/project/foo=prj-foo -ignore-repos /home/me/project1,/home/me/project2'
  '';
}
