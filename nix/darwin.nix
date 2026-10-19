{ pkgs, username, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = username;
  system.stateVersion = 7;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  nix = {
    package = pkgs.lix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  # Homebrew remains the compatibility layer for GUI software that is a
  # better fit as a cask. Existing formulae are intentionally not cleaned up
  # during the first migration pass.
  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
    mutableTaps = true;
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    casks = [
      "brave-browser"
      "discord"
      "font-hack-nerd-font"
      "font-monaspace"
      "kitty"
      "multipass"
      "rectangle"
      "wireshark"
    ];
  };
}
