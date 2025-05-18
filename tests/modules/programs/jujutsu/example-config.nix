{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.jujutsu;
  packageVersion = lib.getVersion cfg.package;

  # jj v0.29+ deprecated support for "~/Library/Application Support" on Darwin.
  configDir =
    if pkgs.stdenv.isDarwin && !(lib.versionAtLeast packageVersion "0.29.0") then
      "Library/Application Support"
    else
      ".config";
in
{
  programs.jujutsu = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    ediff = true;
    settings = {
      user = {
        name = "John Doe";
        email = "jdoe@example.org";
      };
    };
  };

  nmt.script = ''
    assertFileExists 'home-files/${configDir}/jj/config.toml'
    assertFileContent $(normalizeStorePaths 'home-files/${configDir}/jj/config.toml') \
      ${builtins.toFile "expected.toml" ''
        [merge-tools.ediff]
        merge-args = ["$left", "$right", "$base", "$output"]
        program = "/nix/store/00000000000000000000000000000000-emacs-ediff/bin/emacs-ediff"

        [user]
        email = "jdoe@example.org"
        name = "John Doe"
      ''}
  '';
}
