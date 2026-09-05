{ hmInstall ? (import <home-manager> { }).install }:
hmInstall.override {
  shellHook = ''
    exec home-manager init --switch --no-flake -b backup
  '';
}
