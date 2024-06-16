{ pkgs, ... }:

{
  systemd.user.settings.Manager = {
    LogLevel = "debug";
    DefaultCPUAccounting = true;
    DefaultEnvironment = {
      TEST = "abc";
      PATH = "/bin:/sbin:/some where";
    };
  };

  nmt.script = ''
    userConf=home-files/.config/systemd/user.conf
    assertFileExists $userConf
    [ "$(head -n1 "$TESTED/$userConf")" == "[Manager]" ] || exit 1
    assertFileContains $userConf DefaultCPUAccounting=true
    assertFileContains $userConf LogLevel=debug
    assertFileRegex $userConf "^DefaultEnvironment=.*PATH='/bin:/sbin:/some where' .*TEST='abc'"
  '';
}
