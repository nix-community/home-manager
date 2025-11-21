{
  config,
  lib,
  pkgs,
  realPkgs,
  ...
}:

{
  programs = {
    atuin.enable = true;
    nushell.enable = true;
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  # Needed to avoid error with dummy fish package.
  xdg.dataFile."fish/home-manager_generated_completions".source = lib.mkForce (
    builtins.toFile "empty" ""
  );

  nmt.script =
    let
      configDir =
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "home-files/Library/Application Support/nushell"
        else
          "home-files/.config/nushell";
    in
    ''
      assertFileExists "${configDir}/config.nu"
      assertFileRegex "${configDir}/config.nu" \
        'source /nix/store/[^/]*-atuin-nushell-config.nu'
    '';
}
