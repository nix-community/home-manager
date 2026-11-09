{ config, ... }:
{
  programs.bash.enable = true;
  programs.bash.enableCompletion = false;
  programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.opam.enable = true;

  nmt.script = ''
    assertFileContains home-files/.bashrc 'opam_root="''${OPAMROOT-$HOME/.opam}"'
    assertFileContains home-files/.bashrc '[ -f "$opam_root/config" ]'
    assertFileContains home-files/.bashrc 'opam env --shell=bash'

    assertFileContains home-files/.zshrc 'opam_root="''${OPAMROOT-$HOME/.opam}"'
    assertFileContains home-files/.zshrc '[ -f "$opam_root/config" ]'
    assertFileContains home-files/.zshrc 'opam env --shell=zsh'

    assertFileContains home-files/.config/fish/config.fish 'set -q OPAMROOT'
    assertFileContains home-files/.config/fish/config.fish 'if test -f "$opam_root/config"'
    assertFileContains home-files/.config/fish/config.fish 'opam env --shell=fish'

    cat > bash-init <<'EOF'
    ${config.programs.bash.initExtra}
    EOF
    mkdir empty-home
    env -u OPAMROOT HOME="$PWD/empty-home" "$BASH" -c 'source "$1"' _ "$PWD/bash-init" 2> errors
    test ! -s errors
  '';
}
