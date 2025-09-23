# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./apple-silicon-support
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;
  networking = {
    useDHCP  = false;
    interfaces.end0 = {
      ipv4.addresses = [{
        address = "10.10.10.5";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.10.10.1";
    nameservers = ["10.10.10.1"];
  };

  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = true;
  };

  users.users.hummingbot = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.bashInteractive;
  };

    # -------- Packages (CLI only) --------
  programs.bash.completion.enable = true;  # renamed from programs.bash.enableCompletion
  environment.systemPackages = with pkgs; [
    bashInteractive
    ethtool usbutils pciutils
    iproute2 iputils
    curl wget rsync
    vim
    htop
    openssh
    git
  ];


  security.sudo.wheelNeedsPassword = false;
  
  time.timeZone = "America/New_York";

  system.stateVersion = "25.11"; # Did you read the comment?

}

