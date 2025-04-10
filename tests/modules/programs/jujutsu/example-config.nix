{ pkgs, config, ... }:

let
  configDir = if pkgs.stdenv.isDarwin then "Library/Application Support" else ".config";
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
