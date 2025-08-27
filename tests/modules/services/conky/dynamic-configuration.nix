{ config, pkgs, lib, ... }:

let
  homeDirectory = config.home.homeDirectory;
  exampleConfig = ''
    conky.text = [[
      S Y S T E M    I N F O
      $hr
      Host:$alignr $nodename
      Uptime:$alignr $uptime
      RAM:$alignr $mem/$memmax
    ]]
  '';
in {
  services.conky = {
    configs = {
      withFile = {
        enable = true;
        autoStart = true;
        config = "${homeDirectory}/.config/conky/my-conky.conf";
        package = pkgs.conky;
      };

      withConfig = {
        enable = true;
        autoStart = false;
        config = exampleConfig;
        package = pkgs.conky;
      };
      shouldBeDisabled = { enable = false; };
    };
  };

  home.file.".config/conky/my-conky.conf".text = "dummy conky file content";

  nmt.script = ''
    # --- Test the 'withFile' instance ---
    serviceFile1="$TESTED/home-files/.config/systemd/user/conky@withFile.service"

    assertFileExists "$serviceFile1"

    assertFileRegex "$serviceFile1" \
      "ExecStart=.*/bin/conky --config /nix/store/.*-conky-withFile.conf"

    assertFileRegex "$serviceFile1" "ExecStart=${pkgs.conky}/bin/conky --config .*"

    assertFileContains "$serviceFile1" "[Install]"
    assertFileContains "$serviceFile1" "WantedBy=graphical-session.target"

    # --- Test the 'withConfig' instance ---
    serviceFile2="$TESTED/home-files/.config/systemd/user/conky@withConfig.service"

    assertFileExists "$serviceFile2"

    assertFileRegex "$serviceFile2" \
      "ExecStart=.*/bin/conky --config /nix/store/.*-conky-withConfig.conf"

    assertFileNotRegex "$serviceFile2" "\[Install\]"

    generatedConfigFile="$(grep -o '/nix/store/.*-conky-withConfig.conf' "$serviceFile2")"

    assertFileContent "$generatedConfigFile" ${./basic-configuration.conf}

    # --- Test the 'shouldBeDisabled' instance ---
    serviceFile3="$TESTED/home-files/.config/systemd/user/conky@shouldBeDisabled.service"
    assertPathNotExists "$serviceFile3"
  '';
}
