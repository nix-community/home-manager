{ config, pkgs, ... }:

{
  config = {
    programs.swayr = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      systemd.enable = true;
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/swayrd.service

      assertFileExists $serviceFile
      assertFileRegex $serviceFile 'ExecStart=.*/bin/swayrd'
      assertFileRegex $serviceFile 'Environment=RUST_BACKTRACE=1'

      assertPathNotExists home-files/.config/swayr/config.toml
    '';
  };
}
