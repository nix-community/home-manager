{ lib, realPkgs, ... }:

{
  programs = {
    pay-respects.enable = true;
    bash.enable = true;
    zsh.enable = true;
    fish.enable = true;
    nushell.enable = true;
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileRegex \
      home-files/.bashrc \
      'eval "$(/nix/store/[^/]*-pay-respects-[^/]*/bin/pay-respects bash --alias)"'

    assertFileExists home-files/.zshrc
    assertFileRegex \
      home-files/.zshrc \
      'eval "$(/nix/store/[^/]*-pay-respects-[^/]*/bin/pay-respects zsh --alias)"'

    assertFileExists home-files/.config/fish/config.fish
    assertFileRegex \
      home-files/.config/fish/config.fish \
      '/nix/store/[^/]*-pay-respects-[^/]*/bin/pay-respects fish --alias | source'

    assertFileExists home-files/.config/nushell/config.nu
    assertFileRegex \
      home-files/.config/nushell/config.nu \
      'source /nix/store/[^/]*-pay-respects-nushell-config.nu'
  '';
}
