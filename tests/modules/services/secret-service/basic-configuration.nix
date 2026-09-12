{ ... }:
{
  config = {
    services.secret-service = {
      enable = true;
      secrets = [
        {
          label = "Super secret password";
          # Decodes to "password123"
          secretCommand = "echo cGFzc3dvcmQxMjM= | base64 -d";
          attributes = {
            "some-attribute" = "that value";
          };
        }
      ];
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/manage-secret-service-secrets.service
      assertFileExists $serviceFile

      # Assert that the systemd unit has the sd-switch setting
      assertFileRegex $serviceFile 'X-SwitchMethod=restart'

      assertFileRegex $serviceFile 'ExecStart=.*updateSecrets'
      startScript="$(grep -Po '(?<=ExecStart=).*updateSecrets' $TESTED/$serviceFile)"
      assertFileExists "$startScript"

      assertFileRegex $serviceFile 'ExecStop=.*removeSecrets'
      stopScript="$(grep -Po '(?<=ExecStop=).*removeSecrets' $TESTED/$serviceFile)"
      assertFileExists $stopScript

      # Assert that only the secret command and not the secret is in the start script
      assertFileNotRegex $startScript password123
      assertFileRegex $startScript cGFzc3dvcmQxMjM=

      # Assert that the attributes are properly quoted
      assertFileRegex $startScript "some-attribute 'that value'"

      # Assert that neither the secret nor the secret command is not in the stop script
      assertFileNotRegex $stopScript password123
      assertFileNotRegex $stopScript cGFzc3dvcmQxMjM=
    '';
  };
}
