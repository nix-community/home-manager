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
    assertFileContent $userConf ${pkgs.writeText "expected" ''
      [Manager]
      DefaultCPUAccounting=true
      DefaultEnvironment=PATH='/bin:/sbin:/some where' TEST=abc
      LogLevel=debug
      ManagerEnvironment=SYSTEMD_ENVIRONMENT_GENERATOR_PATH=%h/.config/systemd/user-environment-generators:/run/systemd/user-environment-generators:/etc/systemd/user-environment-generators:/usr/local/lib/systemd/user-environment-generators:/usr/lib/systemd/user-environment-generators
    ''}
  '';
}
