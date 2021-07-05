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
      ];
      default = "18.09";
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
  };
}
