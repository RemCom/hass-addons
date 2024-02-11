#!/command/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2034

# user input variables
declare TARGET_DIR
declare KEEP_LOCAL
declare KEEP_REMOTE
declare TRIGGER_TIME
declare TRIGGER_DAYS
declare EXCLUDE_ADDONS
declare EXCLUDE_FOLDERS
declare BACKUP_NAME
declare BACKUP_PWD
declare SKIP_PRECHECK


# smbclient command strings
declare ALL_SHARES


# ------------------------------------------------------------------------------
# Read and print config.
# ------------------------------------------------------------------------------
function get-config {
    export AWS_ACCESS_KEY_ID=$(bashio::config 'aws_access_key' | escape-input)
    export AWS_SECRET_ACCESS_KEY=$(bashio::config 'aws_secret_access_key' | escape-input)
    export AWS_REGION=$(bashio::config 'bucket_region' | escape-input)

    BACKET_NAME=$(bashio::config 'bucket_name')
    STORAGE_CLASS=$(bashio::config 'storage_class')
    BUCKET_REGION=$(bashio::config 'bucket_region')
    KEEP_LOCAL=$(bashio::config 'keep_local')
    KEEP_REMOTE=$(bashio::config 'keep_remote')
    TRIGGER_TIME=$(bashio::config 'trigger_time')
    TRIGGER_DAYS=$(bashio::config 'trigger_days')
    EXCLUDE_ADDONS=$(bashio::config 'exclude_addons')
    EXCLUDE_FOLDERS=$(bashio::config 'exclude_folders')

    bashio::config.exists 'backup_name' && BACKUP_NAME=$(bashio::config 'backup_name') || BACKUP_NAME=""
    bashio::config.exists 'backup_password' && BACKUP_PWD=$(bashio::config 'backup_password') || BACKUP_PWD=""

    bashio::log.info "---------------------------------------------------"
    bashio::log.info "Trigger time: ${TRIGGER_TIME}"
    [[ "$TRIGGER_TIME" != "manual" ]] && bashio::log.info "Trigger days: $(echo "$TRIGGER_DAYS" | xargs)"
    bashio::log.info "---------------------------------------------------"

    return 0
}

# ------------------------------------------------------------------------------
# Escape input given by the user.
#
# Returns the escaped string on stdout
# ------------------------------------------------------------------------------
function escape-input {
    local input
    read -r input

    # escape the evil dollar sign
    input=${input//$/\\$}

    echo "$input"
}

# ------------------------------------------------------------------------------
# Overwrite the backup parameters.
#
# Arguments
#  $1 The json input string
# ------------------------------------------------------------------------------
function overwrite-params {
    local input="$1"
    local addons
    local folders
    local name
    local password

    addons=$(echo "$input" | jq '.exclude_addons[]' 2>/dev/null)
    [[ "$addons" != null  ]] && EXCLUDE_ADDONS="$addons"

    folders=$(echo "$input" | jq '.exclude_folders[]' 2>/dev/null)
    [[ "$folders" != null  ]] && EXCLUDE_FOLDERS="$folders"

    name=$(echo "$input" | jq -r '.backup_name')
    [[ "$name" != null  ]] && BACKUP_NAME="$name"

    password=$(echo "$input" | jq -r '.backup_password')
    [[ "$password" != null  ]] && BACKUP_PWD="$password"

    return 0
}

# ------------------------------------------------------------------------------
# Restore the original backup parameters.
# ------------------------------------------------------------------------------
function restore-params {
    EXCLUDE_ADDONS=$(bashio::config 'exclude_addons')
    EXCLUDE_FOLDERS=$(bashio::config 'exclude_folders')
    bashio::config.exists 'backup_name' && BACKUP_NAME=$(bashio::config 'backup_name') || BACKUP_NAME=""
    bashio::config.exists 'backup_password' && BACKUP_PWD=$(bashio::config 'backup_password') || BACKUP_PWD=""

    return 0
}