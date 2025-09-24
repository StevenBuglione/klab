{
  description = "KLab NixOS flake for modular multi-host setups (Dell x86_64 & Mac Apple Silicon)";

  nixConfig = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  inputs = {
    # Pin nixpkgs to the NixOS 25.05 release for stability.
    # You can switch to nixos-unstable or another channel later if desired.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      mkSystem = { system, modules }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          # Pass self in case your modules want to reference repo paths
          # (e.g., for overlays or additional modules later).
          specialArgs = { inherit self inputs; };
          inherit modules;
        };

      commonModules = [
        ./modules/common/base.nix
        ./modules/common/users.nix
        ./modules/common/ssh.nix
        ./modules/common/laptop-as-server.nix 
        ./modules/common/networking.nix 
        ./modules/common/updates.nix
      ];  

      dellModules = commonModules ++ [
        ./hosts/dell/nixos/configuration.nix
      ];

      macModules = commonModules ++ [
        ./hosts/mac/nixos/configuration.nix
      ];

      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
    in
    {
      # Build or switch with:
      #   nixos-rebuild switch --flake .#dell
      #   nixos-rebuild switch --flake .#mac
      nixosConfigurations = {
        dell = mkSystem { system = "x86_64-linux"; modules = dellModules; };
        mac  = mkSystem { system = "aarch64-linux"; modules = macModules; };
      };

      # Simple devShell for working on this repo.
      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [ nixpkgs-fmt git ];
          };
        }
      );

      # `nix fmt`
      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixpkgs-fmt);
    };
}
