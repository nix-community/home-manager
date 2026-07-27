let
  settings = {
    StreamInputs = {
      inputDevice = "alsa_input.usb-example";
      listenToMic = false;
      obsoleteKey = null;
    };
    StreamOutputs.useDefaultOutputDevice = true;
  };
in
{
  services.easyeffects = {
    enable = true;
    inherit settings;
  };

  test.stubs.easyeffects = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/easyeffects.service

    assertFileExists $serviceFile
    assertFileRegex $serviceFile 'ExecStart=.*/bin/easyeffects'
    assertFileContains $serviceFile \
      'X-Restart-Triggers=${builtins.hashString "sha256" (builtins.toJSON settings)}'

    settingsScript=$(sed -n \
      's|^ExecStartPre=\([^ ]*\).*|\1|p' "$TESTED/$serviceFile")
    assertFileExists "$settingsScript"

    settingsFile='/home/hm-user/.config/easyeffects/db/easyeffectsrc'
    settingsCommand="kwriteconfig6 .*--file $settingsFile"
    inputCommand="$settingsCommand --group StreamInputs"
    outputCommand="$settingsCommand --group StreamOutputs"

    assertFileRegex "$settingsScript" \
      "$inputCommand --key inputDevice -- alsa_input.usb-example"
    assertFileRegex "$settingsScript" \
      "$inputCommand --key listenToMic --type bool -- false"
    assertFileRegex "$settingsScript" \
      "$inputCommand --key obsoleteKey --delete"
    assertFileRegex "$settingsScript" \
      "$outputCommand --key useDefaultOutputDevice --type bool -- true"
    assertFileNotRegex activate "$settingsCommand"
  '';
}
