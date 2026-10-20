{
  home.stateVersion = "26.11";
  home.preferXdgDirectories = true;

  xdg.dataHome = "/data/hm-user";

  programs.gradle = {
    enable = true;
    settings."org.gradle.caching" = true;
  };

  nmt.script = ''
    assertPathNotExists home-files/.gradle
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export GRADLE_USER_HOME="/data/hm-user/gradle"'
  '';
}
