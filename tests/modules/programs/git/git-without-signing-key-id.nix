{ pkgs, ... }: {
  config = {
    programs.git = {
      enable = true;
      userName = "John Doe";
      userEmail = "user@example.org";

      signing = {
        signByDefault = true;
        format = "openpgp";
        key = null;
        program = "path-to-gpg";
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/git/config
      assertFileContent home-files/.config/git/config ${
        ./git-without-signing-key-id-expected.conf
      }
    '';
  };
}
