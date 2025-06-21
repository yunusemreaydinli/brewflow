#!/bin/bash

# Color codes
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
ORANGE='\033[38;5;208m'
CYAN='\033[0;36m'
LIGHT_GREY='\033[38;5;244m'
DARK_GREY='\033[38;5;237m'

# Emojis
ROCKET="🚀"
WARNING="⚠️"
CHECK_MARK="✅"
WRENCH="🔧"
MAGNIFY="🔍"
BUBBLE="🧪"
SPONGE="🧽"
SOAP="🧼"
ARROW="▶️"
ERROR_SIGN="🚧"

# Sound files directory and files
SOUND_DIR="/System/Library/Sounds"
NOTIFY_SUCCESS="Hero.aiff"
NOTIFY_ERROR="Blow.aiff"
NOTIFY_OK="Funk.aiff"
NOTIFY_DONE="Glass.aiff"

# Sound enabled flag
SOUND_ENABLED=true
if ! command -v afplay &> /dev/null; then
    SOUND_ENABLED=false
fi

# Record script start time
script_start=$(date +%s)

# Messages
ERROR_MSG="Error occurred: "
UPDATE_INFO="Updating Homebrew and package info..."
UPDATE_SUCCESS="Homebrew and package info updated."
OUTDATED_INFO="Checking outdated packages..."
OUTDATED_SUCCESS="Outdated packages checked."
UPGRADE_GREEDY_INFO="Upgrading all packages (greedy)..."
UPGRADE_GREEDY_SUCCESS="All packages upgraded."
UPGRADE_INFO="Upgrading packages..."
UPGRADE_SUCCESS="Packages upgraded successfully."
CLEANUP_INFO="Cleaning unnecessary files..."
CLEANUP_SUCCESS="Unnecessary files cleaned."
DEEP_CLEANUP_PROMPT="Do you want to perform deep cleanup? (N/y): "
DEEP_CLEANUP_INFO="Performing deep cleanup..."
DEEP_CLEANUP_SUCCESS="Deep cleanup completed."

ERROR_UPDATE="Homebrew update failed."
ERROR_OUTDATED="Checking outdated packages failed."
ERROR_UPGRADE="Upgrading packages failed."
ERROR_CLEANUP="Cleanup failed."
ERROR_DEEP_CLEANUP="Deep cleanup failed."

DEBUG_PROMPT="Run brew doctor for debugging? (N/y): "
DEBUG_RUNNING="Running brew doctor..."
DEBUG_DONE="Brew doctor completed."
CONTINUE_PROMPT="Continue operation? (Y/n): "
TOTAL_DURATION_LABEL="Total elapsed time: "

# Durations
update_duration=0
outdated_duration=0
upgrade_duration=0
cleanup_duration=0
prune_duration=0

# Play sound function (afplay runs in background)
play_sound() {
    local sound_file="$SOUND_DIR/$1"
    if [[ "$SOUND_ENABLED" == true ]]; then
        afplay "$sound_file" >/dev/null 2>&1 &
    fi
}

# Format duration
format_duration() {
    local duration=$1
    if ((duration < 60)); then
        printf "%ds" "$duration"
    elif ((duration < 3600)); then
        local minutes=$((duration / 60))
        local seconds=$((duration % 60))
        if ((seconds == 0)); then
            printf "%dm" "$minutes"
        else
            printf "%dm %ds" "$minutes" "$seconds"
        fi
    else
        local hours=$((duration / 3600))
        local minutes=$(((duration % 3600) / 60))
        local seconds=$((duration % 60))
        if ((minutes == 0 && seconds == 0)); then
            printf "%dh" "$hours"
        elif ((seconds == 0)); then
            printf "%dh %dm" "$hours" "$minutes"
        else
            printf "%dh %dm %ds" "$hours" "$minutes" "$seconds"
        fi
    fi
}

print_separator() {
    printf "%b\n" "${RED} ────────────────────────────────────────────────────────${RESET}"
}

print_commands_header() {
    printf "%b${ORANGE} ──── COMMANDS ───────────────────────────────── TIME ───${RESET}\n"
}

print_exit_message() {
    local width=65
    local padding_left=$(( (width - 21) / 2 ))
    local padding_right=$(( width - 21 - padding_left ))

    printf "${CYAN}${BOLD}\n%${padding_left}s%s%${padding_right}s${RESET}\n\n" "" "Thank you for using BrewFlow!" ""
    printf "${CYAN}${BOLD}┌─────────────────────────────────────────────────────────────────────┐${RESET}\n"
    printf "${CYAN}${BOLD}│${RESET}  ⭐️  ${BOLD}${YELLOW}Enjoying BrewFlow?${RESET} ${CYAN}Support the project with a star on GitHub!  ${CYAN}${BOLD}│${RESET}\n"
    printf "${CYAN}${BOLD}│${RESET}           ${LIGHT_GREY}${BOLD}👉 https://github.com/yunusemreaydinli/brewflow${RESET}           ${CYAN}${BOLD}│${RESET}\n"
    printf "${CYAN}${BOLD}└─────────────────────────────────────────────────────────────────────┘${RESET}\n\n"
    play_sound "$NOTIFY_DONE"
}

trap_on_interrupt() {
    printf "${RED}${BOLD}\n\n%22s%s${RESET}\n" "" "Operation cancelled by user."
    print_exit_message
    exit 130
}
trap trap_on_interrupt SIGINT

handle_error() {
    local message="$1"
    print_separator
    printf " ${ERROR_SIGN} ${RED}${ERROR_MSG}${message}${RESET}\n"
    play_sound "$NOTIFY_ERROR"

    local total_duration=$((update_duration + outdated_duration + upgrade_duration + cleanup_duration + prune_duration))
    if (( total_duration == 0 )); then
        total_duration=$(( $(date +%s) - script_start ))
    fi
    printf "%b ───────────────────────────────── ${TOTAL_DURATION_LABEL}$(format_duration $total_duration)${RESET}\n" "${ORANGE}"

    printf "%b ${WRENCH} ${LIGHT_GREY}${DEBUG_PROMPT}${RESET}"
    read -r user_input
    user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

    if [[ "$user_input" == "y" || "$user_input" == "yes" ]]; then
        printf "%b ${MAGNIFY} ${YELLOW}${DEBUG_RUNNING}${RESET}\n"
        play_sound "$NOTIFY_OK"
        local start=$(date +%s)
        brew doctor
        local end=$(date +%s)
        local doctor_duration=$((end - start))
        printf "%b ${CHECK_MARK} ${GREEN}${DEBUG_DONE} ${DARK_GREY}─────────────────────${RESET} ${GREEN}Time: $(format_duration $doctor_duration)${RESET}\n"
        total_duration=$((total_duration + doctor_duration))
        play_sound "$NOTIFY_SUCCESS"
        printf "%b ───────────────────────────────── ${TOTAL_DURATION_LABEL}$(format_duration $total_duration)${RESET}\n" "${ORANGE}"
        play_sound "$NOTIFY_DONE"
    fi

    while true; do
        printf "%b ${ARROW} ${LIGHT_GREY}${CONTINUE_PROMPT}${RESET}"
        read -r user_input
        user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
        if [[ "$user_input" == "" || "$user_input" == "y" || "$user_input" == "yes" ]]; then
            return 0
        else
            print_exit_message
            exit 1
        fi
    done
}

run_brew_command() {
    local cmd="$1"
    local info_msg="$2"
    local success_msg="$3"
    local error_msg="$4"
    local emoji="$5"
    local duration_var_name="$6"
    local dash_count="$7"

    printf "%b ${emoji} ${CYAN}${cmd}${RESET} ${YELLOW}${info_msg}${RESET}\n"
    local start=$(date +%s)
    if ! bash -c -- "$cmd"; then
        handle_error "$error_msg"
    fi
    local end=$(date +%s)
    local duration=$((end - start))
    printf -v "$duration_var_name" '%d' "$duration"

    local dashes=$(printf '─%.0s' $(seq 1 $dash_count))
    printf "%b ${CHECK_MARK} ${GREEN}${success_msg} ${DARK_GREY}${dashes}${RESET} ${GREEN}Time: $(format_duration $duration)${RESET}\n"
    play_sound "$NOTIFY_SUCCESS"
}


print_header() {
    clear
    local width=55
    local text="🚀 Welcome to BrewFlow v2.0!"
    local text_len=${#text}
    local padding_left=$(( (width - text_len) / 2 ))
    local padding_right=$(( width - text_len - padding_left - 1 ))

    printf "${CYAN}${BOLD}┌───────────────────────────────────────────────────────┐${RESET}\n"
    printf "${CYAN}${BOLD}│%*s%s%*s│${RESET}\n" "$padding_left" "" "$text" "$padding_right" ""
    printf "${CYAN}${BOLD}└───────────────────────────────────────────────────────┘${RESET}\n\n"
    play_sound "$NOTIFY_DONE"
}

print_warning() {
    clear
    printf "${RED}${BOLD}┌───────────────────────────────────────────────────────┐${RESET}\n"
    printf "${RED}${BOLD}│${RESET} ${WARNING} ${RED}This script runs brew update, upgrade, and${BOLD}         │${RESET}\n"
    printf "${RED}${BOLD}│${RESET} ${RED}   may upgrade packages you didn't explicitly choose. ${BOLD}│${RESET}\n"
    printf "${RED}${BOLD}│${RESET}       ${RED}Proceed only if you accept this behavior.       ${BOLD}│${RESET}\n"
    printf "${RED}${BOLD}└───────────────────────────────────────────────────────┘${RESET}\n\n"
    printf "Press Enter to continue or Ctrl+C to abort..."
    read
}

# Main execution
print_warning
print_header
print_commands_header

run_brew_command "brew update" "$UPDATE_INFO" "$UPDATE_SUCCESS" "$ERROR_UPDATE" "$CHECK_MARK" update_duration 9
run_brew_command "brew outdated" "$OUTDATED_INFO" "$OUTDATED_SUCCESS" "$ERROR_OUTDATED" "$MAGNIFY" outdated_duration 17

# Use --greedy only on macOS
if [[ "$(uname)" == "Darwin" ]]; then
    upgrade_cmd="brew upgrade --greedy"
    upgrade_info="$UPGRADE_GREEDY_INFO"
    upgrade_success="$UPGRADE_GREEDY_SUCCESS"
    run_brew_command "$upgrade_cmd" "$upgrade_info" "$upgrade_success" "$ERROR_UPGRADE" "$BUBBLE" upgrade_duration 21
else
    upgrade_cmd="brew upgrade"
    upgrade_info="$UPGRADE_INFO"
    upgrade_success="$UPGRADE_SUCCESS"
    run_brew_command "$upgrade_cmd" "$upgrade_info" "$upgrade_success" "$ERROR_UPGRADE" "$BUBBLE" upgrade_duration 12
fi

total_duration=$((update_duration + outdated_duration + upgrade_duration + cleanup_duration + prune_duration))
printf "%b ───────────────────────────────── ${TOTAL_DURATION_LABEL}$(format_duration $total_duration)${RESET}\n" "${ORANGE}"
play_sound "$NOTIFY_DONE"

printf "%b ${MAGNIFY} ${LIGHT_GREY}${CYAN}(brew cleanup --prune=1)${RESET} ${LIGHT_GREY}${DEEP_CLEANUP_PROMPT}${RESET}"
read -r user_input
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

if [[ "$user_input" == "y" || "$user_input" == "yes" ]]; then
    printf "%b ${SOAP} ${CYAN}(brew cleanup --prune=1)${RESET} ${YELLOW}${DEEP_CLEANUP_INFO}${RESET}\n"
    play_sound "$NOTIFY_OK"
    start=$(date +%s)
    if ! brew cleanup --prune=1; then
        handle_error "$ERROR_DEEP_CLEANUP"
    fi
    end=$(date +%s)
    prune_duration=$((end - start))

    deep_cleanup_dashes=$(printf '─%.0s' {1..20})


    printf "%b ${CHECK_MARK} ${GREEN}${DEEP_CLEANUP_SUCCESS} ${DARK_GREY}${deep_cleanup_dashes}${RESET} ${GREEN}Time: $(format_duration $prune_duration)${RESET}\n"
    play_sound "$NOTIFY_SUCCESS"

    total_duration=$((total_duration + prune_duration))
    printf "%b ───────────────────────────────── ${TOTAL_DURATION_LABEL}$(format_duration $total_duration)${RESET}\n" "${ORANGE}"

    print_exit_message
    exit 0
else
    print_exit_message
    exit 0
fi
