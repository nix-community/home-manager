{ pkgs, ... }: {
  config = {
    programs.git = {
      enable = true;
      userName = "John Doe";
      userEmail = "user@example.org";

      signing = {
        signByDefault = true;
        format = "openpgp";
        program = "path-to-gpg";
        key = "00112233445566778899AABBCCDDEEFF";
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/git/config
      assertFileContent home-files/.config/git/config ${
        ./git-with-signing-key-id-gpg-expected.conf
      }
    '';
  };
}
