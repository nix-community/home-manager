{
  config,
  pkgs,
  ...
}:

{
  # Exercise merging legacy list definitions with new attrset definitions.
  imports = [
    {
      programs.helix.languages.language-server.nil = {
        command = "nil";
      };
    }
  ];

  programs.helix = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@helix@"; };
    languages = [
      {
        name = "rust";
        auto-format = false;
      }
    ];
  };

  test.asserts.warnings.expected = [
    ''
      Using `programs.helix.languages` as a list is deprecated and will be
      removed in a future release. Please use `programs.helix.languages.language` instead.

      This option now generates the whole languages.toml file instead of just the language array in that file.

      Use:
        programs.helix.languages = { language = <languages list>; }

    ''
  ];

  nmt.script =
    let
      expectedLanguages = pkgs.writeText "helix-languages.expected.toml" ''
        [[language]]
        auto-format = false
        name = "rust"

        [language-server.nil]
        command = "nil"
      '';
    in
    ''
      assertFileContent \
        home-files/.config/helix/languages.toml \
        ${expectedLanguages}
    '';
}
