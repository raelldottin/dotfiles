let
  flake = builtins.getFlake (toString ../..);
  pkgs = import flake.inputs.nixpkgs {
    system = builtins.currentSystem;
    config.allowUnfree = true;
  };
  fixture = flake.inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs.username = builtins.getEnv "DOTFILES_NVIM_TEST_USER";
    modules = [
      ../../nix/home.nix
      ({ lib, ... }: {
        # Use the complete personal module with fixture-only account parameters.
        home.homeDirectory = lib.mkForce (builtins.getEnv "DOTFILES_NVIM_TEST_HOME");
        # The headless CI runner does not provide a user service session.
        systemd.user.enable = false;
      })
    ];
  };
in
{
  activation = fixture.activationPackage;
  tools = fixture.config.home.path;
}
