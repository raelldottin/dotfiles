# Base image for the dotfiles VM tests: a vanilla macOS 27 (Golden Gate)
# install with an `admin` account, automatic login, SSH, passwordless sudo,
# and the Command Line Tools (for Git).
# The account password is generated per build by vm/build-base.sh.
#
# Adapted from cirruslabs/macos-image-templates
# (templates/vanilla-golden-gate.pkr.hcl at 272699ea5afa5aa78a5b9dc20a199c95dad1ef4c,
# MIT License, Copyright (c) 2018 Cirrus Labs). Tart's first-boot provisioning
# creates the account, so no Setup Assistant keystrokes are needed. Build it
# with vm/build-base.sh rather than calling Packer directly.

packer {
  required_plugins {
    tart = {
      version = ">= 1.16.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "ipsw" {
  type        = string
  description = "macOS restore image URL or path; the host must run this macOS version or later."
  default     = "https://updates.cdn-apple.com/2026FallFCS/c9671975-52db-4fb5-9af2-00217169ba8d/UniversalMac_27.2_26B123_Restore.ipsw"
}

variable "vm_name" {
  type    = string
  default = "dotfiles-golden-gate-base"
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Password for the admin account: 12+ characters with letters and digits, no commas."
}

variable "dns_servers" {
  type        = string
  default     = ""
  description = "Comma-separated host resolvers to use if the NAT gateway's DNS does not answer."
}

variable "ssh_public_key" {
  type        = string
  description = "Public key that vm/run-test.sh uses to reach clones of this image."
}

locals {
  username = "admin"
  password = var.password
}

source "tart-cli" "golden_gate" {
  from_ipsw    = var.ipsw
  vm_name      = var.vm_name
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 100
  disk_format  = "asif"
  headless     = true
  ssh_username = local.username
  ssh_password = local.password
  ssh_timeout  = "20m"

  # Requires Tart 2.33.0+ and macOS 27+ on both the host and the guest.
  run_extra_args = [
    "--provisioning-opts=${join(",", [
      "fullName=Dotfiles VM Test",
      "username=${local.username}",
      "password=${local.password}",
      "logsInAutomatically=true",
      "enablesRemoteLogin=true",
    ])}",
  ]

  # Virtualization.framework can report installation done before it is.
  create_grace_time = "30s"

  # Keep the recovery partition so softwareupdate keeps working.
  recovery_partition = "keep"
}

build {
  sources = ["source.tart-cli.golden_gate"]

  provisioner "shell" {
    inline = [
      "echo ${local.password} | sudo -S sh -c \"mkdir -p /etc/sudoers.d && echo '${local.username} ALL=(ALL) NOPASSWD: ALL' | EDITOR=tee visudo -f /etc/sudoers.d/${local.username}-nopasswd\"",
      "sudo systemsetup -settimezone GMT 2>/dev/null",
      "sudo systemsetup -setsleep Off 2>/dev/null",
      "sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0",
      "defaults -currentHost write com.apple.screensaver idleTime 0",
      "sysadminctl -screenLock off -password ${local.password}",
      "mkdir -p ~/.ssh && chmod 700 ~/.ssh",
      "printf '%s\\n' '${var.ssh_public_key}' > ~/.ssh/authorized_keys",
      "chmod 600 ~/.ssh/authorized_keys",
    ]
  }

  provisioner "file" {
    source      = "${path.root}/guest"
    destination = "/tmp/dotfiles-vm-guest"
  }

  provisioner "shell" {
    environment_vars = ["DOTFILES_VM_DNS=${var.dns_servers}"]
    inline = [
      "/bin/bash /tmp/dotfiles-vm-guest/provision-base.sh",
      "rm -rf /tmp/dotfiles-vm-guest",
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo -n true",
      "/usr/bin/git --version",
      "sudo fdesetup status | grep -q 'FileVault is Off'",
      "test ! -e /nix",
      "sw_vers",
    ]
  }
}
