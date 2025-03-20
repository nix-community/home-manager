{ lib, realPkgs, ... }:

{
  programs = {
    pay-respects.enable = true;
    pay-respects.enableBashIntegration = false;
    pay-respects.enableFishIntegration = false;
    pay-respects.enableZshIntegration = false;
    pay-respects.enableNushellIntegration = false;
    bash.enable = true;
    zsh.enable = true;
    fish.enable = true;
    nushell.enable = true;
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script = ''
    assertFileNotRegex home-files/.bashrc '/nix/store/[^/]*-pay-respects-[^/]*/bin/pay-respects'
    assertFileNotRegex home-files/.zshrc '/nix/store/[^/]*-pay-respects-[^/]*/bin/pay-respects'
    assertFileNotRegex home-files/.config/fish/config.fish '/nix/store/[^/]*-pay-respects-[^/]*/bin/pay-respects'
    assertFileNotRegex home-files/.config/nushell/config.nu 'source /nix/store/[^/]*-pay-respects-nushell-config'
  '';
}
