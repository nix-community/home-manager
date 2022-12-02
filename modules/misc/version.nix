{ config, lib, ... }:

with lib;

{
  options = {
    home.stateVersion = mkOption {
      type = types.enum [
        "18.09"
        "19.03"
        "19.09"
        "20.03"
        "20.09"
        "21.03"
        "21.05"
        "21.11"
        "22.05"
        "22.11"
        "23.05"
      ];
      description = ''
        It is occasionally necessary for Home Manager to change
        configuration defaults in a way that is incompatible with
        stateful data. This could, for example, include switching the
        default data format or location of a file.
        </para><para>
        The <emphasis>state version</emphasis> indicates which default
        settings are in effect and will therefore help avoid breaking
        program configurations. Switching to a higher state version
        typically requires performing some manual steps, such as data
        conversion or moving files.
      '';
    };

    home.version = {
      full = mkOption {
        internal = true;
        readOnly = true;
        type = types.str;
        default = let
          inherit (config.home.version) release revision;
          suffix =
            optionalString (revision != null) "+${substring 0 8 revision}";
        in "${release}${suffix}";
        example = "22.11+213a0629";
        description = "The full Home Manager version.";
      };

      release = mkOption {
        internal = true;
        readOnly = true;
        type = types.str;
        default = fileContents ../../.release;
        example = "22.11";
        description = "The Home Manager release.";
      };

      revision = mkOption {
        internal = true;
        type = types.nullOr types.str;
        default = let gitRepo = "${toString ./../..}/.git";
        in if pathIsGitRepo gitRepo then commitIdFromGitRepo gitRepo else null;
        description = ''
          The Git revision from which this Home Manager configuration was built.
        '';
      };
    };
  };
}
