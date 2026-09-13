{
  config,
  pkgs,
  lib,
  realPkgs,
  ...
}:

let
  inherit (pkgs) formats writeScript;
  inherit (lib) mkForce;

  jsonFormat = formats.json { };

  activationScript = writeScript "activation" config.home.activation.configureOpenLinkHub.data;

  settingsExpected = jsonFormat.generate "settings-expected" {
    frontend = false;
    memory = false;
  };
in

{
  services.openlinkhub = {
    enable = true;

    settings = {
      foo = null;
      bar.baz = null;
      qux = { };
    };

    dashboard = {
      enable = false;
      address = "127.0.0.2";
      port = 27004;
      settings = {
        foo = null;
        bar.baz = null;
        qux = { };
      };
    };

    memory = {
      enable = false;
      sku = "CMT64GX5M2B5600Z40";
      smb = "i2c-0";
      type = 5;
    };

    extraConfigs = {
      "test.json" = {
        foo = null;
        bar.baz = null;
        qux = { };
      };
    };
  };

  test.unstubs = [
    (_self: _super: {
      inherit (realPkgs)
        openlinkhub
        rsync
        systemd
        ;
    })
  ];

  home.homeDirectory = mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    export HOME=$TMPDIR/hm-user

    configDir=$HOME/.config/OpenLinkHub

    substitute ${activationScript} $TMPDIR/activate \
      --subst-var TMPDIR \
      --replace-fail 'run ' '''

    chmod +x $TMPDIR/activate
    $TMPDIR/activate

    assertFileExists $configDir/database/rgb.json
    assertFileExists $configDir/config.json

    assertPathNotExists $configDir/dashboard.json
    assertPathNotExists $configDir/test.json

    assertFileContent $configDir/config.json ${settingsExpected}
  '';
}
