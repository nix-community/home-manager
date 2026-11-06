{ lib, pkgs, ... }:

let
  starshipPackage = pkgs.writeShellScriptBin "starship" ''
    if [ "$1" = init ] && [ "$2" = fish ]; then
      printf 'starship fish init args:'
      printf ' %s' "$@"
      printf '\n'
    else
      echo "unexpected starship invocation: $*" >&2
      exit 1
    fi
  '';
in

{
  programs.starship.package = starshipPackage;

  # Needed to avoid error with dummy starship package.
  xdg.dataFile."fish/home-manager/generated_completions".source = lib.mkForce (
    builtins.toFile "empty" ""
  );
}
