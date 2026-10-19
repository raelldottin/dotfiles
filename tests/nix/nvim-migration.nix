let
  flake = builtins.getFlake (toString ../..);
  pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
  personal = flake.homeConfigurations.linux-x86_64.config;
  editor = personal.xdg.configFile.nvim;
  tools = pkgs.buildEnv {
    name = "nvim-migration-tools";
    paths = [ pkgs.neovim pkgs.zsh ];
  };
  fixture = flake.inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      {
        home.username = builtins.getEnv "DOTFILES_NVIM_TEST_USER";
        home.homeDirectory = builtins.getEnv "DOTFILES_NVIM_TEST_HOME";
        home.stateVersion = personal.home.stateVersion;
        home.packages = [ tools ];
        systemd.user.enable = false;
        xdg.enable = true;
        xdg.configFile.nvim = {
          inherit (editor) source recursive;
        };
      }
    ];
  };
in
{
  activation = fixture.activationPackage;
  inherit tools;
}
