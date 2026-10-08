{
  config,
  lib,
  pkgs,
  ...
}:
let
  configFile = lib.elemAt config.home.services.php-fpm.process.argv 2;
in
{
  home.services."php-fpm" = {
    imports = [ pkgs.php.passthru.services.default ];
    configData."php-fpm.conf".source = configFile;
    php-fpm.settings.mypool = {
      listen = "127.0.0.1:9000";
      # FIXME: required by upstream modular service, but ignored when run as user
      "user" = "";
      "pm" = "dynamic";
      "pm.max_children" = 75;
      "pm.min_spare_servers" = 5;
      "pm.max_spare_servers" = 20;
    };
  };
  nmt.script =
    let
      expected = pkgs.writeText "php-fpm.service" ''
        [Install]
        WantedBy=default.target

        [Service]
        ExecReload=${pkgs.coreutils}/bin/kill -USR2 $MAINPID
        ExecStart="@php@/bin/php-fpm" "-y" "${configFile}"
        Restart=always
        RestartSec=5
        RuntimeDirectory=php-fpm
        RuntimeDirectoryPreserve=true
        Type=notify

        [Unit]
        After=network.target
        Documentation=man:php-fpm(8)
        X-Reload-Triggers=${configFile}
      '';
    in
    ''
      assertFileContent home-files/.config/home-services/php-fpm/php-fpm.conf ${./php-fpm.conf}
      assertFileContent home-files/.config/systemd/user/php-fpm.service ${expected}
    '';
}
