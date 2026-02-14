{ config
, lib
, pkgs
, ...
}: {
  config = {
    programs.harsh = {
      enable = true;
      config = {
        "Gym" = "3/7";
        "Code" = 1;
      };
      extraConfig = "Dance: 1w";
    };

    nmt.script = ''
      assertFileExists home-files/.config/harsh/habits
      assertFileContent home-files/.config/harsh/habits ${builtins.toFile "harsh.home-conf.expected" ''
        # This is your habits file.
        # It tells harsh what to track and how frequently.
        # 1 means daily, 7 (or 1w) means weekly, 14 every two weeks.
        # You can also track targets within a set number of days.
        # For example, Gym 3 times a week would translate to 3/7.
        # 0 is for tracking a habit. 0 frequency habits will not warn or score.
        # Examples:

        Code: 1
        Gym: 3/7

        Dance: 1w''}
    '';
  };
}
