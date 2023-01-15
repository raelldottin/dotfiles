#!/bin/bash

# A modification of the homebrew installation script to allow homebrew installation via Jamf
#
# Limitation: This script will only provide the currently logged in user with
# access to the homebrew

# Treat  unset variables as an error when performing parameter expansion.  If expansion
# is attempted on an unset variable, the shell prints an error message, and, if not
# interactive, exits with a non- zero status.
set -u
# After expanding each simple command, for command, case command, select command, or
# arithmetic for command, display the expanded value of PS4, followed by the command and
# its  expanded  arguments  or associated word list.
#set -x

echo "[Starting]Setting up the Homebrew installation prerequisites..."
# Required installation paths. To install elsewhere (which is unsupported)
# you can untar https://github.com/Homebrew/brew/tarball/master
# anywhere you like.
UNAME_MACHINE="$(/usr/bin/uname -m)"

if [[ "${UNAME_MACHINE}" == "arm64" ]]
then
	# On ARM macOS, this script installs to /opt/homebrew only
	HOMEBREW_PREFIX="/opt/homebrew"
	HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}"
else
	# On Intel macOS, this script installs to /usr/local only
	HOMEBREW_PREFIX="/usr/local" HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"
fi

STAT_PRINTF=("stat" "-f")
PERMISSION_FORMAT="%A"
CHOWN=("/usr/sbin/chown")
CHGRP=("/usr/bin/chgrp")
GROUP="admin"
TOUCH=("/usr/bin/touch")
CHMOD=("/bin/chmod")
MKDIR=("/bin/mkdir" "-p")
HOMEBREW_BREW_GIT_REMOTE="https://github.com/Homebrew/brew"
HOMEBREW_CORE_GIT_REMOTE="https://github.com/Homebrew/homebrew-core"
export HOMEBREW_{BREW,CORE}_GIT_REMOTE

# no analytics during installation
export HOMEBREW_NO_ANALYTICS_THIS_RUN=1
export HOMEBREW_NO_ANALYTICS_MESSAGE_OUTPUT=1

RUNAS_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
USER_HOME=$(dscl . read /Users/"${RUNAS_USER}" NFSHomeDirectory | cut -d ' ' -f 2)

HOMEBREW_CORE="${HOMEBREW_REPOSITORY}/Library/Taps/homebrew/homebrew-core"
HOMEBREW_CACHE="${USER_HOME}/Library/Caches/Homebrew"

execute() {
	if ! "$@"
	then
		echo "Failed during: $*"
		exit 1
	fi
}

get_permission() {
  "${STAT_PRINTF[@]}" "${PERMISSION_FORMAT}" "$1"
}

user_only_chmod() {
  [[ -d "$1" ]] && [[ "$(get_permission "$1")" != 75[0145] ]]
}

exists_but_not_writable() {
  sudo -i -u "${RUNAS_USER}" test -e "$1" && ! (sudo -i -u "${RUNAS_USER}" test -r "$1" && sudo -i -u "${RUNAS_USER}" test -w "$1" && sudo -i -u "${RUNAS_USER}" test -x "$1")
}

get_owner() {
  "${STAT_PRINTF[@]}" "%u" "$1"
}

file_not_owned() {
  [[ "$(get_owner "$1")" != "$(id -u "${RUNAS_USER}")" ]]
}

get_group() {
  "${STAT_PRINTF[@]}" "%g" "$1"
}

file_not_grpowned() {
  [[ " $(id -G "${RUNAS_USER}") " != *" $(get_group "$1") "* ]]
}

echo "The following is going to be setup:"
echo "${HOMEBREW_PREFIX}/bin/brew"
echo "${HOMEBREW_PREFIX}/share/doc/homebrew"
echo "${HOMEBREW_PREFIX}/share/man/man1/brew.1"
echo "${HOMEBREW_PREFIX}/share/zsh/site-functions/_brew"
echo "${HOMEBREW_PREFIX}/etc/bash_completion.d/brew"
echo "${HOMEBREW_REPOSITORY}"

directories=(
  bin etc include lib sbin share opt var
  Frameworks
  etc/bash_completion.d lib/pkgconfig
  share/aclocal share/doc share/info share/locale share/man
  share/man/man1 share/man/man2 share/man/man3 share/man/man4
  share/man/man5 share/man/man6 share/man/man7 share/man/man8
  var/log var/homebrew var/homebrew/linked
  bin/brew
)
group_chmods=()
for dir in "${directories[@]}"
do
  if exists_but_not_writable "${HOMEBREW_PREFIX}/${dir}"
  then
    group_chmods+=("${HOMEBREW_PREFIX}/${dir}")
  fi
done

# zsh refuses to read from these directories if group writable
directories=(share/zsh share/zsh/site-functions)
zsh_dirs=()
for dir in "${directories[@]}"
do
  zsh_dirs+=("${HOMEBREW_PREFIX}/${dir}")
done

directories=(
  bin etc include lib sbin share var opt
  share/zsh share/zsh/site-functions
  var/homebrew var/homebrew/linked
  Cellar Caskroom Frameworks
)
mkdirs=()
for dir in "${directories[@]}"
do
  if ! [[ -d "${HOMEBREW_PREFIX}/${dir}" ]]
  then
    mkdirs+=("${HOMEBREW_PREFIX}/${dir}")
  fi
done

user_chmods=()
mkdirs_user_only=()
if [[ "${#zsh_dirs[@]}" -gt 0 ]]
then
  for dir in "${zsh_dirs[@]}"
  do
    if [[ ! -d "${dir}" ]]
    then
      mkdirs_user_only+=("${dir}")
    elif user_only_chmod "${dir}"
    then
      user_chmods+=("${dir}")
    fi
  done
fi

chmods=()
if [[ "${#group_chmods[@]}" -gt 0 ]]
then
  chmods+=("${group_chmods[@]}")
fi
if [[ "${#user_chmods[@]}" -gt 0 ]]
then
  chmods+=("${user_chmods[@]}")
fi

chowns=()
chgrps=()
if [[ "${#chmods[@]}" -gt 0 ]]
then
  for dir in "${chmods[@]}"
  do
    if file_not_owned "${dir}"
    then
      chowns+=("${dir}")
    fi
    if file_not_grpowned "${dir}"
    then
      chgrps+=("${dir}")
    fi
  done
fi

if [[ "${#group_chmods[@]}" -gt 0 ]]
then
  echo "The following existing directories will be made group writable:"
  printf "%s\n" "${group_chmods[@]}"
fi
if [[ "${#user_chmods[@]}" -gt 0 ]]
then
  echo "The following existing directories will be made writable by user only:"
  printf "%s\n" "${user_chmods[@]}"
fi
if [[ "${#chowns[@]}" -gt 0 ]]
then
  echo "The following existing directories will have their owner set to ${RUNAS_USER}:"
  printf "%s\n" "${chowns[@]}"
fi
if [[ "${#chgrps[@]}" -gt 0 ]]
then
  echo "The following existing directories will have their group set to ${GROUP}:"
  printf "%s\n" "${chgrps[@]}"
fi
if [[ "${#mkdirs[@]}" -gt 0 ]]
then
  echo "The following new directories will be created:"
  printf "%s\n" "${mkdirs[@]}"
fi

if [[ -d "${HOMEBREW_PREFIX}" ]]
then
  if [[ "${#chmods[@]}" -gt 0 ]]
  then
    execute "${CHMOD[@]}" "u+rwx" "${chmods[@]}"
  fi
  if [[ "${#group_chmods[@]}" -gt 0 ]]
  then
    execute "${CHMOD[@]}" "g+rwx" "${group_chmods[@]}"
  fi
  if [[ "${#user_chmods[@]}" -gt 0 ]]
  then
    execute "${CHMOD[@]}" "go-w" "${user_chmods[@]}"
  fi
  if [[ "${#chowns[@]}" -gt 0 ]]
  then
    execute "${CHOWN[@]}" "${RUNAS_USER}" "${chowns[@]}"
  fi
  if [[ "${#chgrps[@]}" -gt 0 ]]
  then
    execute "${CHGRP[@]}" "${GROUP}" "${chgrps[@]}"
  fi
fi

if [[ "${#mkdirs[@]}" -gt 0 ]]
then
  execute "${MKDIR[@]}" "${mkdirs[@]}"
  execute "${CHMOD[@]}" "ug=rwx" "${mkdirs[@]}"
  if [[ "${#mkdirs_user_only[@]}" -gt 0 ]]
  then
    execute "${CHMOD[@]}" "go-w" "${mkdirs_user_only[@]}"
  fi
  execute "${CHOWN[@]}" "${RUNAS_USER}" "${mkdirs[@]}"
  execute "${CHGRP[@]}" "${GROUP}" "${mkdirs[@]}"
fi

if ! [[ -d "${HOMEBREW_REPOSITORY}" ]]
then
  execute "${MKDIR[@]}" "${HOMEBREW_REPOSITORY}"
fi
execute "${CHOWN[@]}" "-R" "${RUNAS_USER}:${GROUP}" "${HOMEBREW_REPOSITORY}"

if ! [[ -d "${HOMEBREW_CACHE}" ]]
then
    execute "${MKDIR[@]}" "${HOMEBREW_CACHE}"
fi
if exists_but_not_writable "${HOMEBREW_CACHE}"
then
  execute "${CHMOD[@]}" "g+rwx" "${HOMEBREW_CACHE}"
fi
if file_not_owned "${HOMEBREW_CACHE}"
then
  execute "${CHOWN[@]}" "-R" "${RUNAS_USER}" "${HOMEBREW_CACHE}"
fi
if file_not_grpowned "${HOMEBREW_CACHE}"
then
  execute "${CHGRP[@]}" "-R" "${GROUP}" "${HOMEBREW_CACHE}"
fi
if [[ -d "${HOMEBREW_CACHE}" ]]
then
  execute "${TOUCH[@]}" "${HOMEBREW_CACHE}/.cleaned"
fi
echo "[Complete]Setting up the Homebrew installation prerequisites..."
echo

# Install Xcode Command Line Tools if required
echo "[Starting]Downloading and installing Xcode Command Line Tools..."
major_minor() {
  echo "${1%%.*}.$(
    x="${1#*.}"
    echo "${x%%.*}"
  )"
}

version_gt() {
  [[ "${1%.*}" -gt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -gt "${2#*.}" ]]
}

version_ge() {
  [[ "${1%.*}" -gt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -ge "${2#*.}" ]]
}
# Checks if Xcode CLI tools is already installed

should_install_command_line_tools() {
  macos_version="$(major_minor "$(/usr/bin/sw_vers -productVersion)")"
  if version_gt "${macos_version}" "10.13"
  then
    ! [[ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]]
  else
    ! [[ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]] ||
      ! [[ -e "/usr/include/iconv.h" ]]
  fi
}

# Removes the new line.
chomp() {
  echo -n "${1/"$'\n'"/}"
}

if should_install_command_line_tools && version_ge "${macos_version}" "10.13"
then
	echo "Searching online for the Xcode Command Line Tools"
	clt_placeholder="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
	execute "${TOUCH[@]}" "${clt_placeholder}"
	
	clt_label_command="/usr/sbin/softwareupdate -l |
	                    grep -B 1 -E 'Command Line Tools' |
	                    awk -F'*' '/^ *\\*/ {print \$2}' |
	                    sed -e 's/^ *Label: //' -e 's/^ *//' |
	                    sort -V |
	                    tail -n1"
	clt_label="$(chomp "$(/bin/bash -c "${clt_label_command}")")"
	
	if [[ -n "${clt_label}" ]]
	then
		echo "Installing ${clt_label}"
		execute "/usr/sbin/softwareupdate" "-i" "${clt_label}"
		execute "/bin/rm" "-f" "${clt_placeholder}"
		execute "/usr/bin/xcode-select" "--switch" "/Library/Developer/CommandLineTools"
	fi
else
	echo "Xcode Command Line Tools is already installed."
	echo "Delete /Library/Developer/CommandLineTools to re-install."
fi

echo "[Complete]Downloading and installing Xcode Command Line Tools..."
echo

echo "[Starting]Downloading and installing Homebrew..."
(
	cd "${HOMEBREW_REPOSITORY}" >/dev/null || return

	# we do it in four steps to avoid merge errors when reinstalling
	execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_REPOSITORY}" "init" "-q"

	# "git remote add" will fail if the remote is defined in the global config
	execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_REPOSITORY}" "config" "remote.origin.url" "${HOMEBREW_BREW_GIT_REMOTE}"
	execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_REPOSITORY}" "config" "remote.origin.fetch" "+refs/heads/*:refs/remotes/origin/*"

	# ensure we don't munge line endings on checkout
	execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_REPOSITORY}" "config" "core.autocrlf" "false"

	execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_REPOSITORY}" "fetch" "--force" "origin"
	execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_REPOSITORY}" "fetch" "--force" "--tags" "origin"

	execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_REPOSITORY}" "reset" "--hard" "origin/master"

	if [[ "${HOMEBREW_REPOSITORY}" != "${HOMEBREW_PREFIX}" ]]
	then
		if [[ "${HOMEBREW_REPOSITORY}" == "${HOMEBREW_PREFIX}/Homebrew" ]]
		then
			execute "ln" "-sf" "${HOMEBREW_PREFIX}/Homebrew/bin/brew" "${HOMEBREW_PREFIX}/bin/brew"
		else
			abort "The Homebrew/brew repository should be placed in the Homebrew prefix directory."
		fi
	fi

	if [[ ! -d "${HOMEBREW_CORE}" ]]
	then
		echo "Tapping homebrew/core"
		(
			execute "sudo" "-i" "-u" "${RUNAS_USER}" "${MKDIR[@]}" "${HOMEBREW_CORE}"
			cd "${HOMEBREW_CORE}" >/dev/null || return

			execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_CORE}" "init" "-q"
			execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_CORE}" "config" "remote.origin.url" "${HOMEBREW_CORE_GIT_REMOTE}"
			execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_CORE}" "config" "core.autocrlf" "false"
			execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_CORE}" "fetch" "--force" "origin" "refs/heads/master:refs/remotes/origin/master"
			execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_CORE}" "remote" "set-head" "origin" "--auto" >/dev/null
			execute "sudo" "-i" "-u" "${RUNAS_USER}" "git" "-C" "${HOMEBREW_CORE}" "reset" "--hard" "origin/master"

			cd "${HOMEBREW_REPOSITORY}" >/dev/null || return
		) || exit 1
	fi

	execute "sudo" "-i" "-u" "${RUNAS_USER}" "${HOMEBREW_PREFIX}/bin/brew" "update" "--force" "--quiet"
) || exit 1

echo "[Complete]Downloading and installing Homebrew..."
echo

echo "[Starting]Adding Homebrew to shell environment..."
USER_SHELL=$(dscl . read /Users/"${RUNAS_USER}" UserShell|cut -d " " -f 2)
case "${USER_SHELL}" in
  */bash*)
    if [[ $(sudo -i -u "${RUNAS_USER}" test -r "${USER_HOME}/.bash_profile") ]]
    then
      SHELL_PROFILE="${USER_HOME}/.bash_profile"
    else
      SHELL_PROFILE="${USER_HOME}/.profile"
    fi
    ;;
  */zsh*)
    SHELL_PROFILE="${USER_HOME}/.zprofile"
    ;;
  *)
    SHELL_PROFILE="${USER_HOME}/.profile"
    ;;
esac
if [[ ":$(sudo "-i" "-u" "${RUNAS_USER}" env |grep ^PATH=|cut -d'=' -f2-)):" != *":${HOMEBREW_PREFIX}/bin:"* ]]
then
	umask 177
	sudo -i -u "${RUNAS_USER}" tee -a "${SHELL_PROFILE}" <<EOF
# Home brew shell environments
[[ -x ${HOMEBREW_PREFIX}/bin/brew ]] && eval "\$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
EOF
else
	echo "${HOMEBREW_PREFIX}/bin/brew is already added to your PATH=\"$(sudo -i -u "${RUNAS_USER}" eval echo "\${PATH}")\""
fi
echo "[Complete]Adding Homebrew to shell environment..."
echo
execute "sudo" "-i" "-u" "${RUNAS_USER}" "${HOMEBREW_PREFIX}/bin/brew" "$(cat homebrew_installed_app.txt)"
