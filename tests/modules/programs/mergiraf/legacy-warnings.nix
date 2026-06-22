{
  programs = {
    mergiraf = {
      enable = true;
    };
    git = {
      enable = true;
    };
    jujutsu = {
      enable = true;
    };
  };

  test.asserts.warnings.expected = [
    ''
      The default value of `programs.mergiraf.enableGitIntegration` will change in future versions.
      You are currently using the legacy default (true) because `home.stateVersion` is less than "26.05".
      To silence this warning set:
        programs.mergiraf.enableGitIntegration = true;
    ''
    ''
      The default value of `programs.mergiraf.enableJujutsuIntegration` will change in future versions.
      You are currently using the legacy default (true) because `home.stateVersion` is less than "26.05".
      To silence this warning set:
        programs.mergiraf.enableJujutsuIntegration = true;
    ''
  ];
}
