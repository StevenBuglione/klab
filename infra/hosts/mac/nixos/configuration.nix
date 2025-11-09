{ lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./apple-silicon-support
  ];

  olab.laptopAsServer.enable = false;  # it's a desktop-style server; flip if needed

  boot.loader = {
    efi.canTouchEfiVariables = false;

    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      efiInstallAsRemovable = true;
      timeout = 5;                
    };
  };

  olab.network = {
    hostName = "mac";
    useNetworkManager = false;         # simple static
    dhcp = false;
    static = {
      enable = true;
      interface = "end0";
      address = "10.10.10.5";
      prefixLength = 24;
      gateway = "10.10.10.1";
      nameservers = [ "10.10.10.1" ];
    };
  };


  users.users.sbuglione.extraGroups = [ "wheel" ];

  
  system.autoUpgrade.flags = [ "--update-input" "nixpkgs" "--commit-lock-file" "--impure" ];
  system.stateVersion = "25.11";
}
