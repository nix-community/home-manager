{
  targets-generic-linux = ./generic-linux.nix;
  targets-generic-linux-lix-profile = ./generic-linux-lix-profile.nix;
  targets-generic-linux-recovery = {
    imports = [ ./generic-linux-recovery.nix ];
    _module.args.genericLinuxRecoveryScalarMode = "discovered";
  };
  targets-generic-linux-recovery-home-scalars = {
    imports = [ ./generic-linux-recovery.nix ];
    _module.args.genericLinuxRecoveryScalarMode = "home";
  };
  targets-generic-linux-recovery-zsh-scalars = {
    imports = [ ./generic-linux-recovery.nix ];
    _module.args.genericLinuxRecoveryScalarMode = "zsh";
  };
  targets-generic-linux-gpu-basic = ./generic-linux-gpu/basic-enable.nix;
  targets-generic-linux-gpu-setup-contents = ./generic-linux-gpu/setup-package-contents.nix;
  targets-generic-linux-gpu-nvidia = ./generic-linux-gpu/nvidia-enabled.nix;
  targets-generic-linux-xdg = ./generic-linux-xdg.nix;
}
