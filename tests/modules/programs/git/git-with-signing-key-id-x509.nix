{ pkgs, ... }: {
  config = {
    programs.git = {
      enable = true;
      userName = "John Doe";
      userEmail = "user@example.org";

      signing = {
        signByDefault = true;
        format = "x509";
        program = "path-to-gpgsm";
        key = "00112233445566778899AABBCCDDEEFF";
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/git/config
      assertFileContent home-files/.config/git/config ${
        ./git-with-signing-key-id-x509-expected.conf
      }
    '';
  };
}
