{ config, pkgs, ... }:
{
  config = {
    services.sxhkd = {
      enable = true;
      package = pkgs.runCommandLocal "dummy-package" { } "mkdir $out" // { outPath = "@sxhkd@"; };
      extraOptions = [ "-m 1" ];
      extraPath = "/home/the-user/bin:/extra/path/bin";
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/sxhkd.service

      assertFileExists $serviceFile

      assertFileRegex $serviceFile 'ExecStart=@sxhkd@/bin/sxhkd -m 1'

      assertFileRegex $serviceFile \
        'Environment=PATH=.*\.nix-profile/bin:/home/the-user/bin:/extra/path/bin'
    '';
  };
}
