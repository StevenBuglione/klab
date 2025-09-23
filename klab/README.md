# KLab NixOS flake

This repository now includes a flake that wraps the existing NixOS configurations without changing their behavior. You can evaluate, build, and switch per host with a stable, pinned nixpkgs.

## Hosts
- `dell` → `x86_64-linux` using `infra/hosts/dell/nixos/configuration.nix`
- `mac` → `aarch64-linux` using `infra/hosts/mac/nixos/configuration.nix`

## Quick usage

- Show outputs

```sh
nix flake show
```

- Build a host (dry-run)

```sh
sudo nixos-rebuild build --flake .#dell
sudo nixos-rebuild build --flake .#mac
```

- Switch a host (applies configuration)

```sh
sudo nixos-rebuild switch --flake .#dell
# or on your Apple Silicon Mac (Asahi)
sudo nixos-rebuild switch --flake .#mac
```

- Format Nix files

```sh
nix fmt
```

## Notes
- The flake pins `nixpkgs` to `nixos-25.05` for stability. Change the input in `flake.nix` if you want a different channel.
- If your modules ever need access to repository paths, they can use `specialArgs.self` passed by the flake.
- The host configuration files remain the single source of truth; the flake just wires them into `nixosConfigurations`.

## Dev shell

```sh
nix develop
```

Includes a tiny shell with `git` and `nixpkgs-fmt`.