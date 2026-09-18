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

  testValue = {
    hello = "world";
  };

  testExpected = jsonFormat.generate "test-expected" testValue;
in

{
  services.openlinkhub = {
    enable = true;

    extraConfigs = {
      "test.json" = testValue;
      "foo/test.json" = testValue;
      "foo/bar/test.json" = testValue;
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

    for subpath in test foo/test foo/bar/test; do
      assertFileExists "$configDir"/"$subpath".json
      assertFileContent "$configDir"/"$subpath".json ${testExpected}
    done
  '';
}
