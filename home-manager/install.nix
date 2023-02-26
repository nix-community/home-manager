{ home-manager, runCommand }:

let

  hmBashLibInit = ''
    export TEXTDOMAIN=home-manager
    export TEXTDOMAINDIR=${home-manager}/share/locale
    source ${home-manager}/share/bash/home-manager.sh
  '';

in runCommand "home-manager-install" {
  propagatedBuildInputs = [ home-manager ];
  preferLocalBuild = true;
  shellHookOnly = true;
  shellHook = "exec ${home-manager}/bin/home-manager init --switch --no-flake";
} ''
  ${hmBashLibInit}
  _iError 'This derivation is not buildable, please run it using nix-shell.'
  exit 1
''
