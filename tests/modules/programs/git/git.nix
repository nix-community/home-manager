{ lib, pkgs, ... }:

let

  gitInclude = {
    user = {
      name = "John Doe";
      email = "user@example.org";
    };
  };

  substituteExpected =
    path:
    pkgs.substitute {
      src = path;
      substitutions = [
        "--replace"
        "@git_include_path@"
        (pkgs.writeText "hm_gitconfig" (builtins.readFile ./git-expected-include.conf))
        "--replace"
        "@git_named_include_path@"
        (pkgs.writeText "hm_gitconfigwork" (builtins.readFile ./git-expected-include.conf))
      ];
    };

in
{
  programs.git = lib.mkMerge [
    {
      enable = true;
      package = pkgs.gitMinimal;
      settings = {
        alias = {
          a1 = "foo";
          a2 = "bar";
          escapes = ''"\n	'';
        };
        extra = {
          name = "value";
          multiple = [ 1 ];
        };
        user = {
          email = "user@example.org";
          name = "John Doe";
        };
      };
      ignores = [
        "*~"
        "*.swp"
      ];
      includes = [
        { path = "~/path/to/config.inc"; }
        {
          path = "~/path/to/conditional.inc";
          condition = "gitdir:~/src/dir";
        }
        {
          condition = "gitdir:~/src/dir";
          contents = gitInclude;
        }
        {
          condition = "gitdir:~/src/otherproject";
          contents = gitInclude;
          contentSuffix = "gitconfig-work";
        }
      ];
      signing = {
        signer = "path-to-gpg";
        format = "openpgp";
        key = "00112233445566778899AABBCCDDEEFF";
        signByDefault = true;
      };
      lfs.enable = true;
    }

    {
      settings.alias.a2 = lib.mkForce "baz";
      settings."extra \"backcompat.with.dots\"".previously = "worked";
      settings.extra.boolean = true;
      settings.extra.integer = 38;
      settings.extra.multiple = [ 2 ];
      settings.extra.subsection.value = "test";
    }
  ];

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${substituteExpected ./git-expected.conf}
  '';
}
