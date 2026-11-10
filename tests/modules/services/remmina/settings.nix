{
  config,
  lib,
  pkgs,
  ...
}:

let
  profilePath = ".local/share/remmina/workstation.remmina";
  prefPath = ".config/remmina/remmina.pref";

  preexistingProfile = pkgs.writeText "preexisting.remmina" ''
    [remmina]
    password=encrypted
    quality=0
  '';

  expectedProfile = pkgs.writeText "expected.remmina" ''
    [remmina]
    password=encrypted
    quality=9
    protocol=RDP
    server=workstation.example.org
  '';

  expectedPref = pkgs.writeText "expected.pref" ''
    [remmina_pref]
    rdp_quality_9=A7
  '';

  activationScript = pkgs.writeScript "activation" config.home.activation.remminaSettings.data;
in
{
  services.remmina = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings.remmina_pref.rdp_quality_9 = "A7";

    profiles.workstation = {
      protocol = "RDP";
      server = "workstation.example.org";
      quality = 9;
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    export HOME=$TMPDIR/hm-user

    mkdir -p $HOME/.local/share/remmina
    cat ${preexistingProfile} > $HOME/${profilePath}

    run() { "$@"; }
    substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR

    # Run twice to cover idempotence.
    . $TMPDIR/activate
    . $TMPDIR/activate

    assertFileContent "$HOME/${profilePath}" "${expectedProfile}"
    assertFileContent "$HOME/${prefPath}" "${expectedPref}"
    [[ $(stat -c %a "$HOME/${prefPath}") == 600 ]] || fail "remmina.pref is not private"
  '';
}
