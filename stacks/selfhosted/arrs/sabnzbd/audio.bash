#!/usr/bin/with-contenv bash
# -----------------------------------------------------------------------------
# LOCALLY MAINTAINED -- not auto-updated. Do not overwrite from upstream blindly.
#
#   Source  : https://raw.githubusercontent.com/RandomNinjaAtk/arr-scripts/main/sabnzbd/audio.bash
#   Upstream: RandomNinjaAtk/arr-scripts, scriptVersion 1.9
#   Vendored: 2026-07-31 (upstream 1.9 was current on this date)
#
# LOCAL CHANGE: the SAB_PP_STATUS guard immediately below. Everything else is
# byte-identical to upstream 1.9.
#
# WHY: SABnzbd 5.0 runs post-processing scripts for EVERY job, including FAILED
# ones -- the script must check status itself. The old empty_postproc setting was
# removed upstream. As of 2026-07-31 upstream arr-scripts has NO status check
# (zero SAB_PP_STATUS references), so failed/incomplete downloads would be
# post-processed into the library. See SABnzbd 5.0.0 release notes.
#
# NOTE: scripts_init.bash (in the arr-scripts dir mounted at /custom-cont-init.d)
# is a vendored setup.bash with the script-download blocks removed, precisely so
# this file survives container recreation. If someone restores the stock
# setup.bash, this guard is silently lost.
#
# TO UPDATE: diff against the source URL, re-apply this guard, bump the dates.
# If upstream ever adds its own status check, this guard can be dropped.
# -----------------------------------------------------------------------------

# --- SABnzbd 5.x job-status guard (local addition) ---
# SAB_PP_STATUS: 0 = OK, 1 = failed verification, 2 = failed unpack, 3 = failed
# Older SABnzbd passes status as positional $7 and does not set the env var.
sab_status="${SAB_PP_STATUS:-${7:-0}}"
if [ "$sab_status" != "0" ]; then
  echo "$(date "+%F %T") :: post-processing skipped :: job status $sab_status (not 0/success)"
  exit 0
fi
# --- end guard ---
TITLESHORT="APP"
scriptVersion="1.9"
scriptName="Audio"

#### Import Settings
source /config/extended.conf


log () {
  m_time=`date "+%F %T"`
  echo $m_time" :: $scriptName :: $scriptVersion :: "$1
  echo $m_time" :: $scriptName :: $scriptVersion :: "$1 >> /config/logs/$scriptName.txt
}

logfileSetup () {
  # auto-clean up log file to reduce space usage
  if [ -f "/config/logs/$scriptName.txt" ]; then
    if find /config/logs -type f -name "$scriptName.txt" -size +1024k | read; then
      echo "" > /config/logs/$scriptName.txt
    fi
  fi
  
  if [ ! -f "/config/logs/$scriptName.txt" ]; then
    echo "" > /config/logs/$scriptName.txt
    chmod 666 "/config/logs/$scriptName.txt"
  fi
}

set -e
set -o pipefail


Main () {

	#============FUNCTIONS============

	settings () {

	log "Configuration:"
	log "Script Version: $scriptVersion"
	log "Remove Non Audio Files: ENABLED"
	log "Duplicate File CleanUp: ENABLED"
	if [ "${AudioVerification}" = TRUE ]; then
		log "Audio Verification: ENABLED"
	else
		log "Audio Verification: DISABLED"
	fi
	log "Format: $ConversionFormat"
	if [ "${ConversionFormat}" = FLAC ]; then
		log "Bitrate: lossless"
		log "Replaygain Tagging: ENABLED"
		AudioFileExtension="flac"
	elif [ "${ConversionFormat}" = ALAC ]; then
		log "Bitrate: lossless"
		AudioFileExtension="m4a"
	else
		log "Conversion Bitrate: ${ConversionBitrate}k"
		if [ "${ConversionFormat}" = MP3 ]; then
			AudioFileExtension="mp3"
		elif [ "${ConversionFormat}" = AAC ]; then
			AudioFileExtension="m4a"
		elif [ "${ConversionFormat}" = OPUS ]; then
			AudioFileExtension="opus"
		fi
	fi
	
	if [ "$RequireAudioQualityMatch" = "true" ]; then
		log "Audio Quality Match Verification: ENABLED (.$AudioFileExtension)"
	else
		log "Audio Quality Match Verification: DISABLED"
	fi
	
	if [ "${DetectNonSplitAlbums}" = TRUE ]; then
		log "Detect Non Split Albums: ENABLED"
		log "Max File Size: $MaxFileSize" 
	else
		log "DetectNonSplitAlbums: DISABLED"
	fi

	log "Processing: $1" 

	}
	
		
	AudioQualityMatch  () {
		if [ "$RequireAudioQualityMatch" == "true" ]; then
			find "$1" -type f -not -iname "*.$AudioFileExtension" -delete
			if [ $(find "$1" -type f -iname "*.$AudioFileExtension" | wc -l) -gt 0 ]; then
				log "Verifying Audio Quality Match: PASSED (.$AudioFileExtension)"
			else
				log "Verifying Audio Quality Match"
				log "ERROR: Audio Qualty Check Failed, missing required file extention (.$AudioFileExtension)"
				exit 1
			fi
		fi
	}

	clean () {
		if [ $(find "$1" -type f -regex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" | wc -l) -gt 0 ]; then
			find "$1" -type f -not -regex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" -delete
			find "$1" -mindepth 2 -type f -exec mv "{}" "$1"/ \;
			find "$1" -mindepth 1 -type d -delete
		else
			log "ERROR: NO AUDIO FILES FOUND" && exit 1
		fi
		flacDownloaded="false"
  		mp3Downloaded="false"
  		if [ $(find "$1" -type f -iname "*.flac" | wc -l) -gt 0 ]; then
    			log "FLAC files found"
       			flacDownloaded="true"
       	        fi
		if [ $(find "$1" -type f -iname "*.mp3" | wc -l) -gt 0 ]; then
    			log "MP3 files found"
       			mp3Downloaded="true"
       	        fi

  		if [ "$flacDownloaded" == "true" ]; then
			if [ "$mp3Downloaded" == "true" ]; then
   				log "Deleting duplicate MP3 files.."
   				find "$1" -type f -iname "*.mp3" -delete
       			fi
    		fi
	}

	detectsinglefilealbums () {
		if [ $(find "$1" -type f -regex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" -size +${MaxFileSize} | wc -l) -gt 0 ]; then
			log "ERROR: Non split album detected"
			exit 1
		fi
	}

	verify () {
		if [ $(find "$1" -iname "*.flac" | wc -l) -gt 0 ]; then
			verifytrackcount=$(find  "$1"/ -iname "*.flac" | wc -l)
			log "Verifying: $verifytrackcount Tracks"
			if ! [ -x "$(command -v flac)" ]; then
				log "ERROR: FLAC verification utility not installed (ubuntu: apt-get install -y flac)"
			else
				for fname in "$1"/*.flac; do
					filename="$(basename "$fname")"
					if flac -t --totally-silent "$fname"; then
						log "Verified Track: $filename"
					else
						log "ERROR: Track Verification Failed: \"$filename\""
						rm -rf "$1"/*
						sleep 0.1
						exit 1
					fi
				done
			fi
		fi
		
	}

	conversion () {
		converttrackcount=$(find  "$1"/ -name "*.flac" | wc -l)
		targetformat="$ConversionFormat"
		bitrate="$ConversionBitrate"
		if [ "${ConversionFormat}" = OPUS ]; then
			options="-acodec libopus -ab ${bitrate}k -application audio -vbr off"
			extension="opus"
			targetbitrate="${bitrate}k"
		fi
		if [ "${ConversionFormat}" = AAC ]; then
			options="-acodec aac -ab ${bitrate}k -movflags faststart"
			extension="m4a"
			targetbitrate="${bitrate}k"
		fi
		if [ "${ConversionFormat}" = MP3 ]; then
			options="-acodec libmp3lame -ab ${bitrate}k"
			extension="mp3"
			targetbitrate="${bitrate}k"
		fi
		if [ "${ConversionFormat}" = ALAC ]; then
			options="-acodec alac -movflags faststart"
			extension="m4a"
			targetbitrate="lossless"
		fi
		if [ "${ConversionFormat}" = FLAC ]; then
			options="-acodec flac"
			extension="flac"
			targetbitrate="lossless"
		fi
		if [ -x "$(command -v ffmpeg)" ]; then
			if [ "${ConversionFormat}" = FLAC ]; then
				sleep 0.1
			elif [ $(find "$1"/ -name "*.flac" | wc -l) -gt 0 ]; then
				log "Converting: $converttrackcount Tracks (Target Format: $targetformat (${targetbitrate}))"
				for fname in "$1"/*.flac; do
					filename="$(basename "${fname%.flac}")"
					if [ "${ConversionFormat}" = OPUS ]; then
						opusenc --bitrate ${bitrate} --vbr --music "$fname" "${fname%.flac}.temp.$extension";
						log "Converted: $filename"
						if [ -f "${fname%.flac}.temp.$extension" ]; then
							rm "$fname"
							sleep 0.1
							mv "${fname%.flac}.temp.$extension" "${fname%.flac}.$extension"
						fi
						continue
					else
						log "Conversion failed: $filename, performing cleanup..."
						rm -rf "$1"/*
						sleep 0.1
						exit 1
					fi

					if ffmpeg -loglevel warning -hide_banner -nostats -i "$fname" -n -vn $options "${fname%.flac}.temp.$extension"; then
						log "Converted: $filename"
						if [ -f "${fname%.flac}.temp.$extension" ]; then
							rm "$fname"
							sleep 0.1
							mv "${fname%.flac}.temp.$extension" "${fname%.flac}.$extension"
						fi
					else
						log "Conversion failed: $filename, performing cleanup..."
						rm -rf "$1"/*
						sleep 0.1
						exit 1
					fi
				done
			fi
		else
			log "ERROR: ffmpeg not installed, please install ffmpeg to use this conversion feature"
			sleep 5
		fi
	}

	replaygain () {	
		replaygaintrackcount=$(find  "$1"/ -type f -regex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" | wc -l)
		log "Replaygain: Calculating $replaygaintrackcount Tracks"
		r128gain -r -a "$1" &>/dev/null
	}
	
	beets () {
		trackcount=$(find "$1" -type f -regex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | wc -l)
		log "Matching $trackcount tracks with Beets"
		if [ -f /config/scripts/library.blb ]; then
			rm /config/scripts/library.blb
			sleep 0.1
		fi
		if [ -f /config/scripts/beets/beets.log ]; then 
			rm /config/scripts/beets.log
			sleep 0.1
		fi

		touch "/config/scripts/beets-match"
		sleep 0.1

		if [ $(find "$1" -type f -regex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | wc -l) -gt 0 ]; then
			if [ $(find "$1" -type f -regex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" -newer "/config/scripts/beets-match" | wc -l) -gt 0 ]; then
				log "SUCCESS: Matched with beets!"
			else
			    log "ERROR: Unable to match using beets to a musicbrainz release"
			    if [ $requireBeetsMatch = true ]; then
					rm -rf "$1"/* 
					log "ERROR: Marking download as failed..."
					exit 1
				fi
			fi	
		fi

		if [ -f "/config/scripts/beets-match" ]; then 
			rm "/config/scripts/beets-match"
			sleep 0.1
		fi
	}

	
	#============START SCRIPT============

	settings "$1"
	clean "$1"
	if [ "${DetectNonSplitAlbums}" = TRUE ]; then
		detectsinglefilealbums "$1"
	fi

	if [ "${AudioVerification}" = TRUE ]; then
		verify "$1"
	fi

	conversion "$1"
	
	AudioQualityMatch "$1"

	
	if [ "${BeetsTagging}" = TRUE ]; then
		beets "$1"
	fi
	
	if [ "${ReplaygainTagging}" = TRUE ]; then
		replaygain "$1"
	fi

}

SECONDS=0
Main "$@"
chmod 777 "$1"
chmod 666 "$1"/*
duration=$SECONDS
echo "Post Processing Completed in $(($duration / 60 )) minutes and $(($duration % 60 )) seconds!"

exit $?
