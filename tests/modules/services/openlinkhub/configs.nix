{
  config,
  pkgs,
  lib,
  realPkgs,
  ...
}:

let
  inherit (pkgs) formats writeScript writeText;
  inherit (lib) mkForce;

  jsonFormat = formats.json { };

  cfg = config.services.openlinkhub;

  activationScript = writeScript "activation" config.home.activation.configureOpenLinkHub.data;

  settingsExpected = jsonFormat.generate "settings-expected" (
    cfg.settings
    // {
      frontend = cfg.dashboard.enable;
      listenAddress = cfg.dashboard.address;
      listenPort = cfg.dashboard.port;
      memory = cfg.memory.enable;
      memorySku = cfg.memory.sku;
      memorySmBus = cfg.memory.smb;
      memoryType = cfg.memory.type;
    }
  );

  dashboardExpected = jsonFormat.generate "dashboard-expected" cfg.dashboard.settings;

  profilePreconfigValue = {
    Foo = true;
    Bar = false;
  };

  profilePreconfig = jsonFormat.generate "profile-preconfig" profilePreconfigValue;

  profileExpected = jsonFormat.generate "profile-expected" (
    profilePreconfigValue // cfg.extraConfigs."database/profiles/i2c0.json"
  );

  displayExpected = writeText "display-expected" cfg.extraConfigs."display.json";
in

{
  services.openlinkhub = {
    enable = true;

    settings = {
      debug = false;
      logLevel = "info";
      metrics = false;
    };

    dashboard = {
      enable = true;
      address = "127.0.0.2";
      port = 27004;
      settings = {
        celsius = true;
        languageCode = "en_US";
        pageTitle = "OpenLinkHub WebUI";
      };
    };

    memory = {
      enable = true;
      sku = "CMT64GX5M2B5600Z40";
      smb = "i2c-0";
      type = 5;
    };

    extraConfigs = {
      "database/profiles/i2c0.json" = {
        Active = true;
        Path = "/run/user/1000/OpenLinkHub/database/profiles/i2c0.json";
        Product = "Memory";
        Serial = "i2c0";
      };
      "display.json" = ''
        [
          {
            "Index": 1,
            "Name": "card1-DP-1",
            "Width": 2560,
            "Height": 1440,
            "Left": false,
            "Top": false
          }
        ]
      '';
    };
  };

  test.unstubs = [
    (_self: _super: {
      inherit (realPkgs)
        jq
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

    settingsPath=$configDir/config.json
    dashboardPath=$configDir/dashboard.json
    profilePath=$configDir/database/profiles/i2c0.json
    displayPath=$configDir/display.json

    mkdir -p $configDir/database/profiles
    cat ${profilePreconfig} > $profilePath
    echo 'overwrite me!' > $displayPath

    substitute ${activationScript} $TMPDIR/activate \
      --subst-var TMPDIR \
      --replace-fail 'run ' '''

    chmod +x $TMPDIR/activate
    $TMPDIR/activate

    assertFileExists $settingsPath
    assertFileExists $dashboardPath
    assertFileExists $profilePath
    assertFileExists $displayPath

    assertFileContent $settingsPath ${settingsExpected}
    assertFileContent $dashboardPath ${dashboardExpected}
    assertFileContent $profilePath ${profileExpected}
    assertFileContent $displayPath ${displayExpected}
  '';
}
