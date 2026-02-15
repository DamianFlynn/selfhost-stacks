#!/usr/bin/env bash
# restore-settings-to-lxc.sh
#
# Run this INSIDE the selfhost LXC after Terraform provisioning.
# Restores dotfiles and SSH keys from the TrueNAS backup on /mnt/fast/home/.
#
# Usage:
#   ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/restore-settings-to-lxc.sh'
#
# The script detects the most recent backup automatically, or you can
# pass a specific backup directory:
#   bash restore-settings-to-lxc.sh /mnt/fast/home/.backup-truenas-20260214-1030

set -euo pipefail

# ── Locate backup ─────────────────────────────────────────────────────────────
if [[ -n "${1:-}" ]]; then
  BACKUP_ROOT="$1"
else
  # Pick the most recently created backup directory
  BACKUP_ROOT="$(find /mnt/fast/home -maxdepth 1 -type d -name '.backup-truenas-*' \
    | sort | tail -1)"
fi

if [[ -z "$BACKUP_ROOT" || ! -d "$BACKUP_ROOT" ]]; then
  echo "ERROR: no backup directory found under /mnt/fast/home/.backup-truenas-*"
  echo "Run backup-truenas-settings.sh on TrueNAS first, or pass a path explicitly."
  exit 1
fi

echo
echo "Restoring from: $BACKUP_ROOT"
echo

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "  ✓  $*"; }
warn() { echo "  ⚠  $*"; }
section() { echo; echo "── $* ──────────────────────────────────────────"; }

restore() {
  local src="$1" dst="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    log "$dst"
  fi
}

# ── root dotfiles ─────────────────────────────────────────────────────────────
section "root dotfiles → /root"
SRC="$BACKUP_ROOT/root"

for f in .bashrc .bash_profile .bash_logout \
          .zshrc .zprofile .zlogin .profile \
          .gitconfig .gitconfig.local .gitignore_global \
          .vimrc .nanorc .tmux.conf .editorconfig; do
  restore "$SRC/$f" "/root/$f"
done

restore "$SRC/.config" "/root/.config"
restore "$SRC/.vim"    "/root/.vim"
restore "$SRC/.tmux"   "/root/.tmux"

# ── root SSH keys ─────────────────────────────────────────────────────────────
section "root SSH keys → /root/.ssh"
if [[ -d "$SRC/.ssh" ]]; then
  mkdir -p /root/.ssh
  cp -a "$SRC/.ssh/." /root/.ssh/
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/* 2>/dev/null || true
  chmod 644 /root/.ssh/*.pub 2>/dev/null || true
  log "/root/.ssh (permissions set)"
fi

# ── root GPG keys ─────────────────────────────────────────────────────────────
section "root GPG → /root/.gnupg"
if [[ -d "$SRC/.gnupg" ]]; then
  mkdir -p /root/.gnupg
  cp -a "$SRC/.gnupg/." /root/.gnupg/
  chmod 700 /root/.gnupg
  find /root/.gnupg -type f -exec chmod 600 {} \;
  log "/root/.gnupg"
fi

# ── damian user (create if not present) ───────────────────────────────────────
section "damian user"
DAMIAN_SRC="$BACKUP_ROOT/damian"
if [[ -d "$DAMIAN_SRC" ]]; then
  if ! id damian &>/dev/null; then
    # Create damian as a regular user with home on the fast pool
    useradd -m -d /mnt/fast/home/damian -s /bin/bash \
            -G sudo,docker,apps damian
    log "created user damian (home: /mnt/fast/home/damian)"
  else
    log "user damian already exists"
  fi

  DAMIAN_HOME="$(getent passwd damian | cut -d: -f6)"
  mkdir -p "$DAMIAN_HOME"

  for f in .bashrc .bash_profile .bash_logout \
            .zshrc .zprofile .zlogin .profile \
            .gitconfig .gitconfig.local .gitignore_global \
            .vimrc .nanorc .tmux.conf .editorconfig; do
    restore "$DAMIAN_SRC/$f" "$DAMIAN_HOME/$f"
  done

  restore "$DAMIAN_SRC/.config" "$DAMIAN_HOME/.config"
  restore "$DAMIAN_SRC/.vim"    "$DAMIAN_HOME/.vim"
  restore "$DAMIAN_SRC/.tmux"   "$DAMIAN_HOME/.tmux"

  # SSH keys
  if [[ -d "$DAMIAN_SRC/.ssh" ]]; then
    mkdir -p "$DAMIAN_HOME/.ssh"
    cp -a "$DAMIAN_SRC/.ssh/." "$DAMIAN_HOME/.ssh/"
    chmod 700 "$DAMIAN_HOME/.ssh"
    chmod 600 "$DAMIAN_HOME/.ssh/"* 2>/dev/null || true
    chmod 644 "$DAMIAN_HOME/.ssh/"*.pub 2>/dev/null || true
    log "$DAMIAN_HOME/.ssh (permissions set)"
  fi

  # GPG keys
  if [[ -d "$DAMIAN_SRC/.gnupg" ]]; then
    mkdir -p "$DAMIAN_HOME/.gnupg"
    cp -a "$DAMIAN_SRC/.gnupg/." "$DAMIAN_HOME/.gnupg/"
    chmod 700 "$DAMIAN_HOME/.gnupg"
    find "$DAMIAN_HOME/.gnupg" -type f -exec chmod 600 {} \;
    log "$DAMIAN_HOME/.gnupg"
  fi

  chown -R damian:damian "$DAMIAN_HOME"
  log "ownership set on $DAMIAN_HOME"
else
  warn "No damian backup found in $BACKUP_ROOT — skipping"
fi

# ── SSH host keys (optional — keeps fingerprint identical to TrueNAS) ─────────
section "SSH host keys"
if [[ -d "$BACKUP_ROOT/etc-ssh" ]]; then
  read -rp "  Restore SSH host keys (keeps old fingerprint)? [y/N] " yn
  if [[ "${yn,,}" == "y" ]]; then
    cp "$BACKUP_ROOT/etc-ssh/ssh_host_"* /etc/ssh/ 2>/dev/null || true
    chmod 600 /etc/ssh/ssh_host_*_key 2>/dev/null || true
    chmod 644 /etc/ssh/ssh_host_*_key.pub 2>/dev/null || true
    systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
    log "SSH host keys restored and sshd reloaded"
  else
    log "Skipped — new host keys will be generated (ssh-keygen will re-create on next sshd start)"
  fi
fi

# ── Crontabs ──────────────────────────────────────────────────────────────────
section "Crontabs"
if [[ -f "$BACKUP_ROOT/crontabs/root.crontab" ]]; then
  read -rp "  Restore root crontab? [y/N] " yn
  [[ "${yn,,}" == "y" ]] && crontab "$BACKUP_ROOT/crontabs/root.crontab" \
    && log "root crontab restored"
fi
if [[ -f "$BACKUP_ROOT/crontabs/damian.crontab" ]]; then
  read -rp "  Restore damian crontab? [y/N] " yn
  [[ "${yn,,}" == "y" ]] && crontab -u damian "$BACKUP_ROOT/crontabs/damian.crontab" \
    && log "damian crontab restored"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo
echo "══════════════════════════════════════════════════════"
echo "  Restore complete"
echo "  Source backup : $BACKUP_ROOT"
echo "══════════════════════════════════════════════════════"
echo
echo "Next steps:"
echo "  1. Verify:  ls -la /root/.ssh && ssh-add -l"
echo "  2. Test git: git -C /mnt/fast/stacks status"
echo "  3. If you restored SSH host keys, warn users that"
echo "     'ssh-keygen -R 172.16.1.159' clears the old entry"
