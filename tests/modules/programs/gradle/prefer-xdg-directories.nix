{
  home.stateVersion = "26.11";
  home.preferXdgDirectories = true;

  xdg.dataHome = "/home/hm-user/.local/share-custom";

  programs.gradle = {
    enable = true;
    settings."org.gradle.caching" = true;
  };

  nmt.script = ''
    assertFileExists home-files/.local/share-custom/gradle/gradle.properties
    assertPathNotExists home-files/.gradle
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export GRADLE_USER_HOME="/home/hm-user/.local/share-custom/gradle"'
  '';
}
