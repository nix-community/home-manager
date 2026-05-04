{ lib, pkgs, ... }:

let
  atuinPackage = pkgs.writeShellScriptBin "atuin" ''
    if [ "$1" = init ] && [ "$2" = fish ]; then
      printf 'atuin fish init args:'
      printf ' %s' "$@"
      printf '\n'
    else
      echo "unexpected atuin invocation: $*" >&2
      exit 1
    fi
  '';
in

{
  programs = {
    atuin = {
      enable = true;
      package = atuinPackage;
    };
    fish.enable = true;
  };

  # Needed to avoid error with dummy fish package.
  xdg.dataFile."fish/home-manager/generated_completions".source = lib.mkForce (
    builtins.toFile "empty" ""
  );

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileRegex \
      home-files/.config/fish/config.fish \
      'source /nix/store/[^/]*-atuin-fish-config\.fish'
    assertFileNotRegex home-files/.config/fish/config.fish 'atuin init fish'

    atuinFishConfig=$(
      sed -n 's|^[[:space:]]*source \(/nix/store/[^ ]*-atuin-fish-config\.fish\).*|\1|p' \
        "$TESTED/home-files/.config/fish/config.fish" | head -n1
    )
    assertFileExists "$atuinFishConfig"
    assertFileContains "$atuinFishConfig" \
      'atuin fish init args: init fish'
  '';
}
