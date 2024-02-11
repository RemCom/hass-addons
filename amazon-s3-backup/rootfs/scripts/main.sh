#!/command/with-contenv bashio
# shellcheck shell=bash

declare SLUG
declare SNAP_NAME


# ------------------------------------------------------------------------------
# Create a new backup (full or partial).
# ------------------------------------------------------------------------------
function create-backup {
    local args
    local addons
    local folders

    SNAP_NAME=$(generate-backup-name)

    args=()
    args+=("--name" "$SNAP_NAME")
    [ -n "$BACKUP_PWD" ] && args+=("--password" "$BACKUP_PWD")

    # do we need a partial backup?
    if [[ -n "$EXCLUDE_ADDONS" || -n "$EXCLUDE_FOLDERS" ]]; then
        # include all installed addons that are not listed to be excluded
        addons=$(ha addons --raw-json | jq -rc '.data.addons[] | select (.installed != false) | .slug')
        for ad in ${addons}; do [[ ! $EXCLUDE_ADDONS =~ $ad ]] && args+=("-a" "$ad"); done

        # include all folders that are not listed to be excluded
        folders=(homeassistant ssl share addons/local media)
        for fol in "${folders[@]}"; do [[ ! $EXCLUDE_FOLDERS =~ $fol ]] && args+=("-f" "$fol"); done
    fi

    # run the command
    bashio::log.info "Creating backup \"${SNAP_NAME}\""
    SLUG="$(ha backups new "${args[@]}" --raw-json | jq -r .data.slug)"
}

# ------------------------------------------------------------------------------
# Copy the latest backup to the remote share.
# ------------------------------------------------------------------------------
function copy-backup {
    local store_name
    local input
    local count

    if [ "$SLUG" = "null" ]; then
        bashio::log.error "Error occurred! Backup could not be created! Please try again"
        return 1
    fi

    store_name=$(generate-filename "$SNAP_NAME")

    bashio::log.info "Copying backup ${SLUG} to S3"
    cd /backup || return 1

    bashio::log.debug "Using AWS CLI version: '$(aws --version)'"
    bashio::log.debug "Command: 'aws s3 cp ${SLUG}.tar s3://${BACKET_NAME}/ --no-progress --region ${BUCKET_REGION} --storage-class ${STORAGE_CLASS}'"
    aws s3 cp ${SLUG}.tar s3://${BACKET_NAME}/ --no-progress --region ${BUCKET_REGION} --storage-class ${STORAGE_CLASS}
}

# ------------------------------------------------------------------------------
# Delete old local backups.
# ------------------------------------------------------------------------------
function cleanup-backups-local {
    local snaps
    local slug
    local name

    [ "$KEEP_LOCAL" == "all" ] && return 0

    snaps=$(ha backups --raw-json | jq -c '.data.backups[] | {date,slug,name}' | sort -r)
    bashio::log.debug "List of local backups:\n$snaps"

    echo "$snaps" | tail -n +$((KEEP_LOCAL + 1)) | while read -r backup; do
        slug=$(echo "$backup" | jq -r .slug)
        name=$(echo "$backup" | jq -r .name)
        bashio::log.info "Deleting ${slug} (${name}) local"
        run-and-log "ha backups remove ${slug}"
    done
}