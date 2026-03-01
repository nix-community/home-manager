{
  nmt.script = ''
    hmSessionVarsUserEnvGenerator=home-files/.config/systemd/user-environment-generators/05-home-manager.sh
    assertFileExists $hmSessionVarsUserEnvGenerator
  '';
}
