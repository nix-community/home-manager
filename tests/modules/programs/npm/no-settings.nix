{ ... }:

{
  programs.npm = {
    enable = true;
    settings = { };
  };

  test.stubs.nodejs = { };

  nmt.script = ''
    assertPathNotExists home-files/.npmrc
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      "export NPM_CONFIG_USERCONFIG="
  '';
}
