{
  home.stateVersion = "26.05";
  home.preferXdgDirectories = true;

  xdg.dataHome = "/home/hm-user/.local/share-custom";

  programs.gradle = {
    enable = true;
    settings."org.gradle.caching" = true;
  };

  nmt.script = ''
    assertFileExists home-files/.gradle/gradle.properties
    assertPathNotExists home-files/.local/share-custom/gradle
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      'GRADLE_USER_HOME'
  '';
}
