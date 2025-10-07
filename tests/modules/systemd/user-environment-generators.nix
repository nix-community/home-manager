{ pkgs, ... }:

{
  nmt.script = ''
    hmSessionVarsUserEnvGenerator=home-files/.config/systemd/user-environment-generators/05-home-manager.sh
    assertFileExists $hmSessionVarsUserEnvGenerator
    assertFileContent $hmSessionVarsUserEnvGenerator ${pkgs.writeText "expected" ''
      . "@nix@/etc/profile.d/nix.sh"
      . "/home/hm-user/.nix-profile/etc/profile.d/hm-session-vars.sh"
    ''}
  '';
}
