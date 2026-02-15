#!/usr/bin/env bash
# backup-truenas-settings.sh
#
# Run this ON the TrueNAS host BEFORE wiping it.
# Saves all personal dotfiles, SSH keys, and shell configs to /mnt/fast/home/
# so they survive on the ZFS fast pool and can be restored inside the new LXC.
#
# Usage (from your dev machine):
#   ssh root@<truenas-ip> 'bash -s' < scripts/backup-truenas-settings.sh
#
# Or copy it to TrueNAS and run directly:
#   bash /mnt/fast/stacks/scripts/backup-truenas-settings.sh

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
BACKUP_ROOT="/mnt/fast/home/.backup-truenas-$(date +%Y%m%d-%H%M)"
USERS=("root" "damian")           # adjust if your login user differs
ROOT_HOME="/root"
DAMIAN_HOME=""  # resolved below

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "  ✓  $*"; }
warn() { echo "  ⚠  $*"; }
section() { echo; echo "── $* ──────────────────────────────────────────"; }

copy_if_exists() {
  local src="$1" dst="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    log "$src"
  fi
}

# ── Resolve damian's home ─────────────────────────────────────────────────────
if getent passwd damian &>/dev/null; then
  DAMIAN_HOME="$(getent passwd damian | cut -d: -f6)"
else
  warn "User 'damian' not found — only backing up root"
fi

# ── Create backup directory ───────────────────────────────────────────────────
mkdir -p "$BACKUP_ROOT"
echo
echo "Backup destination: $BACKUP_ROOT"
echo "Started: $(date)"

# ── SSH keys + config ─────────────────────────────────────────────────────────
section "SSH keys"
for home_dir in "$ROOT_HOME" ${DAMIAN_HOME:+"$DAMIAN_HOME"}; do
  user_label="${home_dir##*/}"  # last path component (root or damian)
  dst="$BACKUP_ROOT/$user_label"
  copy_if_exists "$home_dir/.ssh"           "$dst/.ssh"
done

# SSH host keys — keep so the server fingerprint doesn't change after migration
mkdir -p "$BACKUP_ROOT/etc-ssh"
cp /etc/ssh/ssh_host_* "$BACKUP_ROOT/etc-ssh/" 2>/dev/null && log "/etc/ssh/ssh_host_*" \
  || warn "No SSH host keys found in /etc/ssh/"

# ── Shell configs ─────────────────────────────────────────────────────────────
section "Shell configs"
for home_dir in "$ROOT_HOME" ${DAMIAN_HOME:+"$DAMIAN_HOME"}; do
  user_label="${home_dir##*/}"
  dst="$BACKUP_ROOT/$user_label"
  for f in .bashrc .bash_profile .bash_logout .bash_history \
            .zshrc .zsh_history .zprofile .zlogin \
            .profile .shrc; do
    copy_if_exists "$home_dir/$f" "$dst/$f"
  done
done

# ── Git config ────────────────────────────────────────────────────────────────
section "Git config"
for home_dir in "$ROOT_HOME" ${DAMIAN_HOME:+"$DAMIAN_HOME"}; do
  user_label="${home_dir##*/}"
  dst="$BACKUP_ROOT/$user_label"
  for f in .gitconfig .gitconfig.local .gitignore_global; do
    copy_if_exists "$home_dir/$f" "$dst/$f"
  done
done

# ── GPG keys ──────────────────────────────────────────────────────────────────
section "GPG keys"
for home_dir in "$ROOT_HOME" ${DAMIAN_HOME:+"$DAMIAN_HOME"}; do
  user_label="${home_dir##*/}"
  dst="$BACKUP_ROOT/$user_label"
  copy_if_exists "$home_dir/.gnupg" "$dst/.gnupg"
done

# ── Application config (~/.config) ───────────────────────────────────────────
section "~/.config"
for home_dir in "$ROOT_HOME" ${DAMIAN_HOME:+"$DAMIAN_HOME"}; do
  user_label="${home_dir##*/}"
  dst="$BACKUP_ROOT/$user_label"
  copy_if_exists "$home_dir/.config" "$dst/.config"
done

# ── Editor configs ────────────────────────────────────────────────────────────
section "Editor configs"
for home_dir in "$ROOT_HOME" ${DAMIAN_HOME:+"$DAMIAN_HOME"}; do
  user_label="${home_dir##*/}"
  dst="$BACKUP_ROOT/$user_label"
  for f in .vimrc .vim .nanorc .tmux.conf .tmux .editorconfig; do
    copy_if_exists "$home_dir/$f" "$dst/$f"
  done
done

# ── Crontabs ──────────────────────────────────────────────────────────────────
section "Crontabs"
mkdir -p "$BACKUP_ROOT/crontabs"
for user in root damian; do
  if crontab -l -u "$user" &>/dev/null 2>&1; then
    crontab -l -u "$user" > "$BACKUP_ROOT/crontabs/$user.crontab"
    log "crontab for $user"
  fi
done
# System crontabs
copy_if_exists /etc/cron.d  "$BACKUP_ROOT/etc-cron.d"
copy_if_exists /etc/crontab "$BACKUP_ROOT/etc-crontab"

# ── .env files from stacks (belt-and-suspenders) ─────────────────────────────
section ".env files from stacks"
mkdir -p "$BACKUP_ROOT/env-files"
find /mnt/fast/stacks -name '.env' -not -path '*/node_modules/*' | while read -r f; do
  rel="${f#/mnt/fast/stacks/}"
  dest="$BACKUP_ROOT/env-files/${rel//\//__}"   # flatten path with __
  cp "$f" "$dest"
  log "$f → env-files/${rel//\//__}"
done

# ── Summary tarball ───────────────────────────────────────────────────────────
section "Creating tarball"
TARBALL="/mnt/fast/home/backup-truenas-$(date +%Y%m%d-%H%M).tar.gz"
tar -czf "$TARBALL" -C "$(dirname "$BACKUP_ROOT")" "$(basename "$BACKUP_ROOT")"
log "tarball: $TARBALL"

# ── Final summary ─────────────────────────────────────────────────────────────
echo
echo "══════════════════════════════════════════════════════"
echo "  Backup complete"
echo "  Directory : $BACKUP_ROOT"
echo "  Tarball   : $TARBALL"
echo "  Both live on /mnt/fast — safe across the Proxmox install"
echo "══════════════════════════════════════════════════════"
echo
echo "Contents:"
find "$BACKUP_ROOT" -not -type d | sed "s|$BACKUP_ROOT/||" | sort | sed 's/^/    /'
