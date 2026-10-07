{
  description = "Raell Dottin's declarative macOS and Linux workstation configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      username = "raelldottin";

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      mkHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = { inherit username; };
          modules = [ ./nix/home.nix ];
        };
    in
    {
      darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs username; };
        modules = [
          ./nix/darwin.nix
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = { inherit username; };
            home-manager.users.${username} = import ./nix/home.nix;
          }
        ];
      };

      homeConfigurations.linux-x86_64 = mkHome "x86_64-linux";
      homeConfigurations.linux-aarch64 = mkHome "aarch64-linux";

      formatter = {
        aarch64-darwin = (mkPkgs "aarch64-darwin").nixfmt-rfc-style;
        x86_64-linux = (mkPkgs "x86_64-linux").nixfmt-rfc-style;
        aarch64-linux = (mkPkgs "aarch64-linux").nixfmt-rfc-style;
      };
    };
}
