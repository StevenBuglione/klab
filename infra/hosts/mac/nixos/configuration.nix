{ lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./apple-silicon-support
  ];

  klab.laptopAsServer.enable = false;  # it's a desktop-style server; flip if needed

  klab.network = {
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

  klab.hummingbot.docker = {
    enable = true;
    user = "hummingbot";
    mode = "rootful";
  };

  users.users.hummingbot.extraGroups = [ "wheel" "networkmanager" "docker" ];

  environment.systemPackages = with pkgs; [ ethtool usbutils pciutils ];
  
  system.autoUpgrade.flags = [ "--update-input" "nixpkgs" "--commit-lock-file" "--impure" ];
  system.stateVersion = "25.11";
}

