{ config, lib, pkgs, ... }:

with lib;

let

  gitInclude = {
    user = {
      name = "John Doe";
      email = "user@example.org";
    };
  };

  substituteExpected = path:
    pkgs.substituteAll {
      src = path;
      git_include_path = pkgs.writeText "hm_gitconfig"
        (builtins.readFile ./git-expected-include.conf);
      git_named_include_path = pkgs.writeText "hm_gitconfigwork"
        (builtins.readFile ./git-expected-include.conf);
    };

in {
  config = {
    programs.git = mkMerge [
      {
        enable = true;
        package = pkgs.gitMinimal;
        aliases = {
          a1 = "foo";
          a2 = "bar";
          escapes = ''"\n	'';
        };
        extraConfig = {
          extra = {
            name = "value";
            multiple = [ 1 ];
          };
        };
        ignores = [ "*~" "*.swp" ];
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
        userEmail = "user@example.org";
        userName = "John Doe";
        lfs.enable = true;
        delta = {
          enable = true;
          options = {
            features = "decorations";
            whitespace-error-style = "22 reverse";
            decorations = {
              commit-decoration-style = "bold yellow box ul";
              file-style = "bold yellow ul";
              file-decoration-style = "none";
            };
          };
        };
      }

      {
        aliases.a2 = mkForce "baz";
        extraConfig."extra \"backcompat.with.dots\"".previously = "worked";
        extraConfig.extra.boolean = true;
        extraConfig.extra.integer = 38;
        extraConfig.extra.multiple = [ 2 ];
        extraConfig.extra.subsection.value = "test";
      }
    ];

    test.stubs = {
      git-lfs = { };
      delta = { };
    };

    nmt.script = ''
      assertFileExists home-files/.config/git/config
      assertFileContent home-files/.config/git/config ${
        substituteExpected ./git-expected.conf
      }
    '';
  };
}
