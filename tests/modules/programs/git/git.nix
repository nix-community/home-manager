{ config, pkgs, lib, ... }:

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

      deltaCommand = "${pkgs.gitAndTools.delta}/bin/delta";

      git_include_path = pkgs.writeText "contents"
        (builtins.readFile ./git-expected-include.conf);
    };
in {
  programs.git = lib.mkMerge [
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
      ];
      signing = {
        gpgPath = "path-to-gpg";
        key = "00112233445566778899AABBCCDDEEFF";
        signByDefault = true;
      };
      userEmail = "user@example.org";
      userName = "John Doe";
      lfs.enable = true;
      delta = {
        enable = true;
        options = [ "--dark" ];
      };
    }

    {
      aliases.a2 = lib.mkForce "baz";
      extraConfig."extra \"backcompat.with.dots\"".previously = "worked";
      extraConfig.extra.boolean = true;
      extraConfig.extra.integer = 38;
      extraConfig.extra.multiple = [ 2 ];
      extraConfig.extra.subsection.value = "test";
    }
  ];

  nmt.script = ''
    assertFileExists $home_files/.config/git/config
    assertFileContent $home_files/.config/git/config ${
      substituteExpected ./git-expected.conf
    }
  '';
}
