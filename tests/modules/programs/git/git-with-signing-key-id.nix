{ pkgs, ... }: {
  config = {
    programs.git = {
      enable = true;
      userName = "John Doe";
      userEmail = "user@example.org";

      signing = {
        gpgPath = "path-to-gpg";
        key = "00112233445566778899AABBCCDDEEFF";
        signByDefault = true;
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/git/config
      assertFileContent home-files/.config/git/config ${
        ./git-with-signing-key-id-expected.conf
      }
    '';
  };
}
