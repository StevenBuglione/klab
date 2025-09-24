{ config, lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types mkIf mkMerge;
in
{
  options.klab.network = {
    hostName = mkOption {
      type = types.str;
      default = "nixos";
      description = "System hostname";
    };

    # Choose a manager; defaults work for most laptops.
    useNetworkManager = mkOption {
      type = types.bool;
      default = true;
      description = "Use NetworkManager instead of basic networking.* options";
    };

    # Simple DHCP toggle when not using NetworkManager (or as a fallback).
    dhcp = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DHCP globally if not using NetworkManager or for quick setups";
    };

    # Static IPv4 (single interface helper).
    static = {
      enable = mkEnableOption "configure a single static IPv4";
      interface = mkOption { type = types.str; default = "end0"; };
      address = mkOption { type = types.str; default = ""; };
      prefixLength = mkOption { type = types.int; default = 24; };
      gateway = mkOption { type = types.str; default = ""; };
      nameservers = mkOption { type = types.listOf types.str; default = [ "1.1.1.1" "8.8.8.8" ]; };
    };
  };

  config = mkMerge [
    {
      networking.hostName = config.klab.network.hostName;
    }

    # NetworkManager path
    (mkIf config.klab.network.useNetworkManager {
      networking.networkmanager.enable = true;
      # If you still want DHCP via NM, leave static.disable
      networking.useDHCP = config.klab.network.dhcp;
    })

    # Non-NM path (basic networking.*)
    (mkIf (!config.klab.network.useNetworkManager) {
      networking.useDHCP = config.klab.network.dhcp;
    })

    # Static helper (applies regardless of NM off/on; useful for servers without NM)
    (mkIf config.klab.network.static.enable {
      networking.useDHCP = false;
      networking.interfaces.${config.klab.network.static.interface}.ipv4.addresses = [{
        address = config.klab.network.static.address;
        prefixLength = config.klab.network.static.prefixLength;
      }];
      networking.defaultGateway = config.klab.network.static.gateway;
      networking.nameservers = config.klab.network.static.nameservers;
    })
  ];
}
