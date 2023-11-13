{ lib, options, ... }: {
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

    test.asserts.warnings.expected = [
      "The option `programs.git.signing.gpgPath' defined in ${
        lib.showFiles options.programs.git.signing.gpgPath.files
      } has been renamed to `programs.git.signing.signer'."
    ];

    nmt.script = ''
      assertFileExists home-files/.config/git/config
      assertFileContent home-files/.config/git/config ${
        ./git-with-signing-key-id-legacy-expected.conf
      }
    '';
  };
}
