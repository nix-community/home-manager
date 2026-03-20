{
  config,
  lib,
  pkgs,
  ...
}:

let
  configPath = ".local/share/PrismLauncher/prismlauncher.cfg";

  preexistingConfig = pkgs.writeText "preexisting.cfg" ''
    [General]
    ApplicationTheme=system
    MaxMemAlloc=8192
    MinMemAlloc=512
  '';

  expectedConfig = pkgs.writeText "expected.cfg" ''
    [General]
    ApplicationTheme=dark
    MaxMemAlloc=8192
    MinMemAlloc=512
    ConsoleMaxLines=100000
    ShowConsole=true
  '';

  activationScript = pkgs.writeScript "activation" config.home.activation.prismlauncherConfigActivation.data;
in

{
  programs.prismlauncher = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      ApplicationTheme = "dark";
      ShowConsole = true;
      ConsoleMaxLines = 100000;
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    export HOME=$TMPDIR/hm-user

    # write preexisting config
    mkdir -p $HOME/.local/share/PrismLauncher
    cat ${preexistingConfig} > $HOME/${configPath}

    # run the activation script
    substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
    chmod +x $TMPDIR/activate
    $TMPDIR/activate

    # validate the merged config
    assertFileExists "$HOME/${configPath}"
    assertFileContent "$HOME/${configPath}" "${expectedConfig}"

    # test idempotence
    $TMPDIR/activate
    assertFileExists "$HOME/${configPath}"
    assertFileContent "$HOME/${configPath}" "${expectedConfig}"
  '';
}
