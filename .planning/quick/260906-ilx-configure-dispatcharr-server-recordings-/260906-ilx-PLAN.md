# Server recordings for Jellyfin

User approved server recording with a 250 GB limit and no automatic deletion.

1. Declare a quota-limited ZFS dataset and persistent LXC mount in Terraform.
   Preserve the container lifecycle guards. Apply only a reviewed saved plan.
2. Bind the dataset to Dispatcharr's fixed recording root and read-only into
   Jellyfin. Publish compose changes through git. Recreate only idle services.
3. Create a Jellyfin home-video library named TV Recordings, with local metadata
   writes and internet metadata disabled. Keep encoding settings unchanged.
4. Check mount identity, write/read permissions, quota and library configuration;
   make a short recording on an idle aerial tuner and verify Jellyfin indexes it.

Live pause/catch-up integration is deferred. Do not consume an occupied IPTV slot.
