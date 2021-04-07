{ pkgs, ... }: {
  config = {
    programs.git = {
      enable = true;
      userName = "John Doe";
      userEmail = "user@example.org";

      signing = {
        gpgPath = "path-to-gpg";
        key = null;
        signByDefault = true;
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
