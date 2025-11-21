{
  config,
  ...
}:

{
  programs.hwatch = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = ''
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh "HWATCH"
  '';
}
