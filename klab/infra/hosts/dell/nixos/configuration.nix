# /etc/nixos/configuration.nix
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # -------- Boot --------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # -------- Host & Time --------
  networking.hostName = "nixos";
  time.timeZone = "America/New_York";

  # -------- Locale --------
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # -------- HEADLESS: No GUI, TTY only --------
  services.xserver.enable = false;
  console.keyMap = "us";

  # -------- Networking --------
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  # USB-C Ethernet reliability (Realtek RTL8153, etc.)
  hardware.enableAllFirmware = true;
  boot.kernelModules = [
    "usbnet" "cdc_ncm" "cdc_ether" "rndis_host"
    "r8152"          # Realtek RTL8152/8153/8156
    "ax88179_178a"   # ASIX USB 3.0 GbE
  ];
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];
  boot.extraModprobeConfig = ''
    options r8152 bEnableEEE=0
  '';

  # Optional (docks/Thunderbolt)
  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;

  # -------- SSH (server) --------
  services.openssh = {
    enable = true;
    settings = {
      # moved here per deprecation warning
      PermitRootLogin = "no";            # or "prohibit-password", "yes"
      X11Forwarding = false;
      PasswordAuthentication = true;     # set to false after keys are installed
      KbdInteractiveAuthentication = false;
    };
  };

  # -------- Power / Laptop-as-Server behaviors --------
  services.logind.lidSwitch = "ignore";
  services.logind.lidSwitchDocked = "ignore";
  services.logind.lidSwitchExternalPower = "ignore";

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    SuspendState=
    HibernateState=
  '';

  # -------- User --------
  users.users.hummingbot = {
    isNormalUser = true;
    description = "Steven Buglione";
    extraGroups = [ "wheel" "networkmanager" ];
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
  ];

  # -------- Nixpkgs --------
  nixpkgs.config.allowUnfree = true;

  # -------- State version --------
  system.stateVersion = "25.05";
}
