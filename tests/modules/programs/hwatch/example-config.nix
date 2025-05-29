{
  config,
  ...
}:

{
  programs.hwatch = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    extraArgs = [
      "--exec"
      "--precise"
    ];
  };

  nmt.script = ''
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh 'HWATCH="--exec --precise"'
  '';
}
