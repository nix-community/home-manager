{
  programs.zsh = {
    enable = true;
    envExtra = "envExtra";
    profileExtra = "profileExtra";
    loginExtra = "loginExtra";
    logoutExtra = "logoutExtra";
    sessionVariables.FOO = "bar";
    prezto = {
      enable = true;
      extraConfig = "configExtra";
    };
  };

  test.stubs = {
    zsh-prezto = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/share/zsh-prezto/runcoms
        echo '# zprofile' > $out/share/zsh-prezto/runcoms/zprofile
        echo '# zlogin' > $out/share/zsh-prezto/runcoms/zlogin
        echo '# zlogout' > $out/share/zsh-prezto/runcoms/zlogout
        echo '# zshenv' > $out/share/zsh-prezto/runcoms/zshenv
        echo '# zshrc' > $out/share/zsh-prezto/runcoms/zshrc
      '';
    };
  };

  nmt.script = ''
    assertFileContains home-files/.zpreztorc 'configExtra'
    assertFileContains home-files/.zprofile 'profileExtra'
    assertFileContains home-files/.zlogin 'loginExtra'
    assertFileContains home-files/.zlogout 'logoutExtra'
    assertFileContains home-files/.zshenv 'envExtra'
    # make sure we are loading the environment variables
    assertFileContains home-files/.zshenv \
      '. "/home/hm-user/.nix-profile/etc/profile.d/hm-session-vars.sh"'
    assertFileContains home-files/.zshenv \
      'export FOO="bar"'
  '';
}
