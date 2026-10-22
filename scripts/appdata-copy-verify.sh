#!/usr/bin/env bash
# appdata-copy-verify.sh — copy one app's state onto a ZFS dataset and PROVE the copy is exact.
#
# Usage (as root, INSIDE LXC 100):
#   appdata-copy-verify.sh SRC DST LABEL
#   appdata-copy-verify.sh --self-test
#
# Exit codes: 0 copied and proven identical; 1 copy or proof FAILED (DST holds a partial or wrong
# copy, so do NOT start the app on it); 2 REFUSED before anything was written. A refusal is never a
# pass (CONVENTIONS 1).
#
# WHY cp -a, and not rsync. rsync is not installed in LXC 100. The tank workaround
# `rsync -rlt --no-p --no-o --no-g` must NOT be used here: it exists because tank (nfsv4 +
# aclmode=restricted) refuses chmod/chown, and it DROPS owner and mode, which a Postgres PGDATA
# cannot survive. fast/appdata is posix/discard (and automation is nfsv4/passthrough), and both
# accept chmod and chown, so GNU `cp -a` keeps owner, mode, timestamps, hard links and symlinks.
#
# WHY inside the LXC. Container uids are native there (postgres 999 or 70, grafana 472, trek 1000),
# and the unprivileged idmap shifts them on write (999 -> host 100999). The same copy run on
# atlantis would have to hand-shift every uid.
#
# WHAT THE PROOF IS. Two manifests per side, kept under /root/cg6/LABEL.{src,dst}.{meta,sha}:
#   meta: type, numeric uid, gid, octal mode, link count, path, symlink target, and for
#         non-directories the apparent size and mtime (%T@, ns precision; cp -a preserves it). DIRECTORY SIZE IS OMITTED ON
#         PURPOSE: ext4 reports 4096 and ZFS reports entries+2, so it can never match. Directory
#         nlink (subdirs+2) agrees on both and is kept (measured 2026-10-22).
#   sha:  sha256 of every regular file, relative paths, C-sorted.
# Both pairs must be byte-identical (`cmp`). /root/cg6/LABEL.ok is written only then, and the
# 261022-cg6 T6 delete guard keys on it. /root/cg6 is on LXC root deliberately: /tmp is a tmpfs,
# and the pending-mount branch reboots the LXC.
#
# WHAT WOULD FALSIFY THE PROOF. A source written to during the copy: both manifests are taken
# after the copy, so a write between cp and the source manifest would show up as a mismatch (a
# red), but a write before cp read that file and after it would not. That is why every step stops
# the app first. The proof also says nothing about xattrs or ACLs. The 2026-10-22 preflight
# measured zero of either in every source, and cp is made to fail on any warning, which is how
# it reports a dropped xattr or ACL.
#
# GUARDS (all exit 2, nothing written): EUID 0; SRC a directory; DST an existing EMPTY directory;
# `findmnt -no FSTYPE -T DST` = zfs (the assertion that would have caught every rootfs case in
# 261022-cg6); SRC and DST on different devices; LABEL [a-z0-9-]+ with no existing LABEL.ok.
# There is no environment knob that skips a guard (CONVENTIONS 4). --self-test bypasses ONLY the
# fstype and device guards, by calling the internal functions directly, because its fixture
# necessarily sits on one filesystem.
set -euo pipefail

PROOF_DIR=/root/cg6

refuse() { echo "REFUSED: $*" >&2; exit 2; }
fail()   { echo "FAIL: $*" >&2; exit 1; }

guard_root()  { [ "${EUID}" -eq 0 ] || refuse "must run as root (EUID=${EUID})"; }
guard_label() {
  [[ "$1" =~ ^[a-z0-9-]+$ ]] || refuse "LABEL '$1' must match [a-z0-9-]+"
  [ ! -e "$2/$1.ok" ] || refuse "$2/$1.ok already exists: a proof for this label is on record; use a new label"
}
guard_dirs() {  # SRC DST
  [ -d "$1" ] && [ ! -L "$1" ] || refuse "SRC '$1' is not a directory"
  [ -d "$2" ] && [ ! -L "$2" ] || refuse "DST '$2' does not exist or is not a directory (create it with install -d first)"
  [ -z "$(find "$2" -mindepth 1 -maxdepth 1 -print -quit)" ] || refuse "DST '$2' is not empty"
}
guard_fstype() {  # DST
  local t; t="$(findmnt -no FSTYPE -T "$1" 2>/dev/null || true)"
  [ "$t" = zfs ] || refuse "DST '$1' is on '${t:-unknown}', not zfs: the bytes would not land on a dataset"
}
guard_device() {  # SRC DST
  local a b; a="$(stat -c %d "$1")"; b="$(stat -c %d "$2")"
  [ "$a" != "$b" ] || refuse "SRC and DST share device $a: this is not a move onto a new dataset"
}

# do_copy SRC DST WORKDIR. Copy, then give the bind root the owner, mode and mtime the container saw.
do_copy() {
  local src="$1" dst="$2" err="$3/cp.stderr" rc=0
  cp -a --sparse=always "$src/." "$dst/" 2>"$err" || rc=$?
  if [ "$rc" -ne 0 ] || [ -s "$err" ]; then
    echo "cp exited $rc. stderr (any line is a failure, because cp only WARNS about dropped xattr/ACL):" >&2
    head -20 "$err" >&2
    return 1
  fi
  chown --reference="$src" "$dst"
  chmod --reference="$src" "$dst"
  touch -r "$src" "$dst"
}

manifest_meta() {  # ROOT
  ( cd "$1" && {
      find . -type d -printf 'd %U %G %#m - %n - %P\n'
      find . ! -type d -printf '%y %U %G %#m %s %n %T@ %P -> %l\n'
    } | LC_ALL=C sort )
}
manifest_sha() {  # ROOT
  ( cd "$1" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum )
}

# verify SRC DST OUTDIR LABEL. Write the four manifests and compare them. 0 = identical.
verify() {
  local src="$1" dst="$2" out="$3" l="$4" bad=0 k
  manifest_meta "$src" >"$out/$l.src.meta"; manifest_meta "$dst" >"$out/$l.dst.meta"
  manifest_sha  "$src" >"$out/$l.src.sha";  manifest_sha  "$dst" >"$out/$l.dst.sha"
  for k in meta sha; do
    if ! cmp -s "$out/$l.src.$k" "$out/$l.dst.$k"; then
      echo "MISMATCH $l ($k manifest): first 20 diff lines (< src, > dst):" >&2
      diff "$out/$l.src.$k" "$out/$l.dst.$k" | head -20 >&2 || true
      bad=1
    fi
  done
  return "$bad"
}

summary_line() {  # ROOT LABEL
  local n b
  n="$(find "$1" -type f | wc -l)"
  b="$(find "$1" -type f -printf '%s\n' | awk '{s+=$1} END {printf "%d", s}')"
  echo "OK $2 files=$n bytes=$b"
}

main() {
  [ "$#" -eq 3 ] || { echo "usage: $0 SRC DST LABEL | --self-test" >&2; exit 2; }
  local src="${1%/}" dst="${2%/}" label="$3"
  guard_root
  guard_label "$label" "$PROOF_DIR"
  guard_dirs "$src" "$dst"
  guard_fstype "$dst"
  guard_device "$src" "$dst"
  install -d -m 0700 "$PROOF_DIR"
  do_copy "$src" "$dst" "$PROOF_DIR" || fail "copy of $label did not complete cleanly; DST '$dst' holds a PARTIAL copy"
  verify "$src" "$dst" "$PROOF_DIR" "$label" || fail "$label: manifests differ. Do NOT start the app on '$dst'"
  local line; line="$(summary_line "$dst" "$label")"
  { echo "$line"; echo "src=$src dst=$dst at=$(date -u +%FT%TZ)"
    sha256sum "$PROOF_DIR/$label".{src,dst}.{meta,sha}; } >"$PROOF_DIR/$label.ok"
  echo "$line"
}

self_test() {
  guard_root
  local T pass=0 failc=0 out rc
  T="$(mktemp -d)"; trap 'rm -rf "$T"' RETURN
  ok()  { echo "  PASS  $*"; pass=$((pass+1)); }
  bad() { echo "  FAIL  $*"; failc=$((failc+1)); }
  mkdir -p "$T/src/private" "$T/src/sub" "$T/proof"
  echo "regular file" >"$T/src/regular.txt"
  chmod 0700 "$T/src/private"; echo "secret" >"$T/src/private/inside"
  truncate -s 64M "$T/src/sparse.bin"; printf 'tail' >>"$T/src/sparse.bin"
  echo "linked" >"$T/src/sub/hl-a"; ln "$T/src/sub/hl-a" "$T/src/sub/hl-b"
  ln -s ../regular.txt "$T/src/sub/symlink"
  echo "pg" >"$T/src/pgfile"; chown 999:999 "$T/src/pgfile"
  chown 999:999 "$T/src"; chmod 1777 "$T/src"

  echo "Case 1: clean copy of the fixture"
  mkdir "$T/dst"
  if do_copy "$T/src" "$T/dst" "$T" && verify "$T/src" "$T/dst" "$T/proof" clean; then ok "copy + verify exit 0"; else bad "clean copy did not verify"; fi
  [ "$(stat -c %i "$T/dst/sub/hl-a")" = "$(stat -c %i "$T/dst/sub/hl-b")" ] && ok "hard-link pair is one inode in DST" || bad "hard link split"
  [ "$(stat -c '%u:%g %a' "$T/dst")" = "999:999 1777" ] && ok "DST root carries SRC owner/mode 999:999 1777" || bad "DST root is $(stat -c '%u:%g %a' "$T/dst")"
  [ "$(stat -c '%u:%g' "$T/dst/pgfile")" = "999:999" ] && ok "999:999 file kept its owner" || bad "999 owner lost"
  [ "$(stat -c %a "$T/dst/private")" = 700 ] && ok "0700 dir kept its mode" || bad "0700 lost"
  [ "$(readlink "$T/dst/sub/symlink")" = ../regular.txt ] && ok "symlink kept its target" || bad "symlink target"
  [ "$(( $(stat -c %b "$T/dst/sparse.bin") * $(stat -c %B "$T/dst/sparse.bin") ))" -lt 1048576 ] \
    && ok "64 MiB sparse file is still sparse ($(du -k "$T/dst/sparse.bin" | cut -f1) KiB allocated)" || bad "sparse file was filled"

  echo "Case 2: one flipped byte in a DST file must go red and name the path"
  # mtime is put back after the flip, so the meta manifest matches and ONLY sha256 can catch it.
  printf 'X' | dd of="$T/dst/regular.txt" bs=1 seek=0 conv=notrunc status=none
  touch -r "$T/src/regular.txt" "$T/dst/regular.txt"
  rc=0; out="$(verify "$T/src" "$T/dst" "$T/proof" flip 2>&1)" || rc=$?
  [ "$rc" -eq 1 ] && grep -q 'regular.txt' <<<"$out" && grep -q '(sha manifest)' <<<"$out" && ! grep -q '(meta manifest)' <<<"$out" \
    && ok "exit 1 from the sha manifest alone, names ./regular.txt" || bad "flip not caught by sha alone (rc=$rc)"
  printf 'r' | dd of="$T/dst/regular.txt" bs=1 seek=0 conv=notrunc status=none
  touch -r "$T/src/regular.txt" "$T/dst/regular.txt"

  echo "Case 3: a 0700 dir chmod'ed 0755 in DST must go red (meta manifest)"
  chmod 0755 "$T/dst/private"
  rc=0; out="$(verify "$T/src" "$T/dst" "$T/proof" mode 2>&1)" || rc=$?
  [ "$rc" -eq 1 ] && grep -q 'private' <<<"$out" && grep -q '(meta manifest)' <<<"$out" && ok "exit 1 from the meta manifest, names private" || bad "mode change not caught (rc=$rc)"
  chmod 0700 "$T/dst/private"
  verify "$T/src" "$T/dst" "$T/proof" restored && ok "restored DST verifies again (control)" || bad "control did not re-verify"

  echo "Case 4: refusals exit 2 and write nothing"
  mkdir "$T/empty"
  rc=0; ( main "$T/src" "$T/dst" t-nonempty ) >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] && ok "non-empty DST refused (2)" || bad "non-empty DST rc=$rc"
  rc=0; ( main "$T/src" "$T/empty" t-notzfs ) >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] && [ -z "$(ls -A "$T/empty")" ] && ok "non-zfs DST refused (2), DST still empty" || bad "non-zfs rc=$rc"
  rc=0; ( guard_device "$T/src" "$T/empty" ) >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] && ok "same-device SRC/DST refused (2)" || bad "same-device rc=$rc"
  rc=0; runuser -u nobody -- bash -c "$(declare -f refuse guard_root); guard_root" >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] && ok "non-root refused (2)" || bad "non-root rc=$rc"
  rc=0; ( main "$T/src" ) >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] && ok "wrong arg count refused (2)" || bad "usage rc=$rc"
  [ ! -e "$PROOF_DIR/t-nonempty.ok" ] && [ ! -e "$PROOF_DIR/t-notzfs.ok" ] && ok "no proof file written for a refused run" || bad "a refused run wrote a proof"

  echo
  echo "📊 1. Summary"
  echo "  cases passed: $pass"
  echo "  cases failed: $failc"
  [ "$failc" -eq 0 ] && { echo "  SELF-TEST GREEN"; return 0; }
  echo "  SELF-TEST RED"; return 1
}

if [ "${1:-}" = "--self-test" ]; then
  self_test
else
  main "$@"
fi
