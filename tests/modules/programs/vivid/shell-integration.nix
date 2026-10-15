{ lib, pkgs, ... }:
{
  test.stubs.vivid = {
    name = "vivid";
    outPath = null;
    buildScript = ''
      mkdir -p "$out/bin"
      cat > "$out/bin/vivid" <<'EOF'
      #!${pkgs.runtimeShell}
      set -eu
      if [ "$1" = -m ]; then
        test "$2" = 8-bit
        test -r "$VIVID_DATABASE"
        test -r "$4"
        shift 2
      fi
      test "$1" = generate
      test "$2" = molokai || test -r "$2"
      printf 'di=01;34\n'
      EOF
      chmod +x "$out/bin/vivid"
    '';
  };

  programs.bash.enable = true;
  programs.zsh.enable = true;
  programs.fish.enable = true;
  programs.nushell = {
    enable = true;
    configDir = ".config/nushell";
  };
  programs.vivid = {
    enable = true;
    activeTheme = lib.mkDefault "molokai";
  };

  nmt.script = ''
    for file in .bashrc .zshrc .config/fish/config.fish .config/nushell/env.nu; do
      assertFileRegex "home-files/$file" '/nix/store/.*-vivid-ls-colors'
    done
    assertFileContains home-files/.bashrc 'export LS_COLORS="$(<'
    assertFileContains home-files/.zshrc 'export LS_COLORS="$(<'
    assertFileContains home-files/.config/fish/config.fish 'string collect < /nix/store/'
    assertFileContains home-files/.config/nushell/env.nu 'open --raw /nix/store/'
    colors=$(grep -o '/nix/store/[^"]*-vivid-ls-colors' "$TESTED/home-files/.bashrc")
    assertFileContains "$colors" 'di=01;34'
  '';
}
