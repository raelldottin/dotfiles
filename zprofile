# Find Homebrew on either Mac architecture without installing or updating it.
for _dotfiles_brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [[ -x "$_dotfiles_brew" ]]; then
    eval "$("$_dotfiles_brew" shellenv)"
    break
  fi
done
unset _dotfiles_brew
