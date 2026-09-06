# Server DVR configured

Completed 2026-09-06. Implementation: `85f6d26`; runbook and scan helper: `e5076cd`.

- Terraform saved targeted plan: 1 create, 0 changes, 0 destroys. Applied
  `null_resource.dispatcharr_recordings`; quota 250,000,000,000 bytes, mounted=yes.
- `tank/media/Recordings` is mounted on LXC 100 at `/mnt/tank/media/Recordings`,
  persisted as mp31. Live mount propagation worked without restarting LXC 100.
- Dispatcharr and Jellyfin were idle, recreated at their existing versions with
  identical environment values. Recording binds are rw and ro respectively.
- Jellyfin TV Recordings library uses `/recordings`, homevideos, real-time
  monitoring, no internet metadata, no local metadata writes. Encoding settings
  were compared before/after and unchanged (hardware acceleration remains off).
- A 35-second RTÉ One aerial recording (DVR id 1) completed and remuxed to MKV.
  The retained sample is `TV_Shows/DVR setup test/20260906_123426.mkv`.
  ffprobe as UID 568 read H.264 video, MP2 audio, 35.02-second duration; 9,953,758 bytes.
- Jellyfin indexed item `b3dfd7e8104d7bd1d8377636bfe8020c`. Its authenticated
  playback endpoint returned HTTP 206 for bytes 0-1023 with the Matroska signature.
- Initial empty-root scan skipped recordings. A normal library scan after the
  first recording discovered the folder; log at 13:38:51 confirms Watching
  directory /recordings. The targeted refresh alone did not discover the root.
- Terraform validate, format check, Python compilation and git diff check passed.
- Required quick health script: no unhealthy containers; music checks and
  Jellyfin retention checks passed. Traefik localhost:8080 dashboard probe failed;
  this check is outside the recording path and no Traefik changes were made.

No IPTV connection was used for testing. Sports channels 402/440/442 have no
catch-up flags; live pause integration remains deferred. No automatic deletion,
recording schedule for tonight, or TiviMate device configuration was added.

Operational note: the broad `/mnt/fast` df check initially described the wrong
filesystem. Actual Dispatcharr appdata was on fast/appdata/media (1.4 TB free);
the correction was communicated before deployment. Recordings are now separately
bounded on tank regardless.
