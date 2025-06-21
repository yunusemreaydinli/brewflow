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

# Upgrade prompts
STABLE_UPGRADE_INFO="Checking stable outdated packages..."
GREEDY_UPGRADE_INFO="Checking all outdated packages (including pre-release)..."
NO_OUTDATED_MSG="No outdated packages found."
UPGRADE_CONFIRM_PROMPT="Proceed with upgrade? (Y/n): "
UPGRADE_CHOICE_PROMPT_MACOS="Choose upgrade option:\n  ${GREEN}1)${RESET} Upgrade outdated packages ${LIGHT_GREY}(default)${RESET}\n  ${YELLOW}2)${RESET} Show all packages (including pre-release with --greedy)\nChoice (1-2): "
UPGRADE_CHOICE_PROMPT_OTHER="Choose upgrade option:\n  ${GREEN}1)${RESET} Upgrade outdated packages ${LIGHT_GREY}(default)${RESET}\nChoice (1): "
NO_STABLE_CHOICE_PROMPT="No stable packages to upgrade. Check with --greedy?\n  ${YELLOW}1)${RESET} Check for pre-release versions (--greedy) ${LIGHT_GREY}(default)${RESET}\n  ${RED}2)${RESET} Skip upgrade\nChoice (1-2): "
GREEDY_SELECTION_PROMPT="Choose upgrade option:\n  ${GREEN}1)${RESET} Upgrade only outdated packages ${LIGHT_GREY}(default)${RESET}\n  ${YELLOW}2)${RESET} Upgrade only greedy packages\n  ${ORANGE}3)${RESET} Upgrade all packages\nChoice (1-3): "

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

check_and_show_outdated() {
    local cmd="$1"
    local info_msg="$2"
    local emoji="$3"
    
    printf "%b ${emoji} ${CYAN}${cmd}${RESET} ${YELLOW}${info_msg}${RESET}\n"
    local start=$(date +%s)
    
    local outdated_output
    outdated_output=$(bash -c -- "$cmd" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        handle_error "Checking outdated packages failed."
        return 1
    fi
    
    local end=$(date +%s)
    local duration=$((end - start))
    outdated_duration=$duration
    
    if [[ -z "$outdated_output" || "$outdated_output" =~ ^[[:space:]]*$ ]]; then
        printf "%b ${CHECK_MARK} ${GREEN}${NO_OUTDATED_MSG} ${DARK_GREY}──────────────────${RESET} ${GREEN}Time: $(format_duration $duration)${RESET}\n"
        play_sound "$NOTIFY_SUCCESS"
        return 2
    else
        printf "%b ${CHECK_MARK} ${GREEN}Outdated packages found: ${DARK_GREY}──────────────${RESET} ${GREEN}Time: $(format_duration $duration)${RESET}\n"
        printf "%b\n" "${LIGHT_GREY}${outdated_output}${RESET}\n"
        play_sound "$NOTIFY_SUCCESS"
        return 0
    fi
}

# Handle greedy selection after showing greedy packages
handle_greedy_selection() {
    printf "%b ${ARROW} ${LIGHT_GREY}${GREEDY_SELECTION_PROMPT}${RESET}"
    
    while true; do
        read -r greedy_choice
        # Default to option 1 if empty
        if [[ -z "$greedy_choice" ]]; then
            greedy_choice=1
        fi
        case $greedy_choice in
            1)
                # Upgrade only outdated packages
                show_package_selection "brew outdated" "brew upgrade"
                selection_result=$?
                if [[ $selection_result -eq 0 ]]; then
                    # Upgrade all stable packages
                    run_brew_command "brew upgrade" "$UPGRADE_INFO" "$UPGRADE_SUCCESS" "$ERROR_UPGRADE" "$BUBBLE" upgrade_duration 12
                elif [[ $selection_result -eq 1 ]]; then
                    # Skip upgrade
                    upgrade_duration=0
                    printf "%b ${YELLOW}Upgrade skipped by user.${RESET}\n"
                fi
                # If selection_result is 3, individual package was already upgraded
                break
                ;;
            2)
                # Upgrade only greedy packages
                show_package_selection "brew outdated --greedy" "brew upgrade --greedy"
                selection_result=$?
                if [[ $selection_result -eq 0 ]]; then
                    # Upgrade all packages with greedy
                    run_brew_command "brew upgrade --greedy" "$UPGRADE_GREEDY_INFO" "$UPGRADE_GREEDY_SUCCESS" "$ERROR_UPGRADE" "$BUBBLE" upgrade_duration 21
                elif [[ $selection_result -eq 1 ]]; then
                    # Skip upgrade
                    upgrade_duration=0
                    printf "%b ${YELLOW}Upgrade skipped by user.${RESET}\n"
                fi
                # If selection_result is 3, individual package was already upgraded
                break
                ;;
            3)
                # Upgrade all packages
                show_package_selection "brew outdated --greedy" "brew upgrade --greedy"
                selection_result=$?
                if [[ $selection_result -eq 0 ]]; then
                    # Upgrade all packages with greedy
                    run_brew_command "brew upgrade --greedy" "$UPGRADE_GREEDY_INFO" "$UPGRADE_GREEDY_SUCCESS" "$ERROR_UPGRADE" "$BUBBLE" upgrade_duration 21
                elif [[ $selection_result -eq 1 ]]; then
                    # Skip upgrade
                    upgrade_duration=0
                    printf "%b ${YELLOW}Upgrade skipped by user.${RESET}\n"
                fi
                # If selection_result is 3, individual package was already upgraded
                break
                ;;
            *)
                printf "%b ${ERROR_SIGN} ${RED}Invalid choice. Please select 1, 2, or 3.${RESET}\n"
                printf "%b ${ARROW} ${LIGHT_GREY}${GREEDY_SELECTION_PROMPT}${RESET}"
                ;;
        esac
    done
}

show_package_selection() {
    local cmd="$1"
    local upgrade_cmd_base="$2"
    
    # Get list of outdated packages with versions - make sure to use --verbose
    local verbose_cmd
    if [[ "$cmd" == *"--greedy"* ]]; then
        verbose_cmd="brew outdated --greedy --verbose"
    else
        verbose_cmd="brew outdated --verbose"
    fi
    
    local outdated_output
    outdated_output=$(bash -c -- "$verbose_cmd" 2>/dev/null)
    
    if [[ -z "$outdated_output" ]]; then
        return 2
    fi
    
    # Convert to arrays for package names and full info
    local packages=()
    local package_info=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local package_name=$(echo "$line" | awk '{print $1}')
            packages+=("$package_name")
            package_info+=("$line")
        fi
    done <<< "$outdated_output"
    
    printf "%b\n${CYAN}${BOLD}Select packages to upgrade:${RESET}\n"
    printf "%b  ${GREEN}0)${RESET} All packages ${LIGHT_GREY}(default)${RESET}\n"
    
    local i=1
    for info in "${package_info[@]}"; do
        printf "%b  ${YELLOW}%d)${RESET} %s\n" "" "$i" "$info"
        ((i++))
    done
    printf "%b  ${RED}%d)${RESET} Skip upgrade\n" "" "$i"
    
    printf "%b\n${ARROW} ${LIGHT_GREY}Choice (0-%d or multiple like '1 2 3'): ${RESET}" "" "$i"
    read -r package_choice
    
    # Default to option 0 if empty
    if [[ -z "$package_choice" ]]; then
        package_choice=0
    fi
    
    if [[ "$package_choice" == "0" ]]; then
        # Upgrade all packages
        return 0
    elif [[ "$package_choice" == "$i" ]]; then
        # Skip upgrade
        return 1
    else
        # Handle multiple selections or single selection
        local selected_packages=()
        local valid_choices=()
        
        # Split input by spaces and validate each choice
        for choice in $package_choice; do
            if [[ "$choice" -ge 1 && "$choice" -lt "$i" ]]; then
                selected_packages+=("${packages[$((choice-1))]}")
                valid_choices+=("$choice")
            else
                printf "%b ${ERROR_SIGN} ${RED}Invalid choice: %s. Please select numbers between 1-%d.${RESET}\n" "" "$choice" "$((i-1))"
                show_package_selection "$cmd" "$upgrade_cmd_base"
                return
            fi
        done
        
        if [[ ${#selected_packages[@]} -eq 0 ]]; then
            printf "%b ${ERROR_SIGN} ${RED}No valid packages selected.${RESET}\n"
            show_package_selection "$cmd" "$upgrade_cmd_base"
            return
        fi
        
        # Upgrade selected packages one by one
        local start=$(date +%s)
        local all_success=true
        
        for package in "${selected_packages[@]}"; do
            printf "%b ${BUBBLE} ${CYAN}${upgrade_cmd_base} ${package}${RESET} ${YELLOW}Upgrading ${package}...${RESET}\n"
            if ! bash -c -- "${upgrade_cmd_base} ${package}"; then
                handle_error "Upgrading ${package} failed."
                all_success=false
            else
                printf "%b ${CHECK_MARK} ${GREEN}${package} upgraded successfully.${RESET}\n"
            fi
        done
        
        local end=$(date +%s)
        upgrade_duration=$((end - start))
        
        if [[ "$all_success" == true ]]; then
            local dashes=$(printf '─%.0s' $(seq 1 12))
            printf "%b ${CHECK_MARK} ${GREEN}Selected packages upgraded successfully. ${DARK_GREY}${dashes}${RESET} ${GREEN}Time: $(format_duration $upgrade_duration)${RESET}\n"
            play_sound "$NOTIFY_SUCCESS"
        else
            printf "%b ${WARNING} ${YELLOW}Some packages failed to upgrade. Check output above.${RESET}\n"
        fi
        
        return 3
    fi
}

prompt_upgrade_choice() {
    printf "%b ${ARROW} ${LIGHT_GREY}${UPGRADE_CONFIRM_PROMPT}${RESET}"
    read -r user_input
    user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$user_input" == "" || "$user_input" == "y" || "$user_input" == "yes" ]]; then
        return 0
    else
        return 1
    fi
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

# First, check stable outdated packages
check_and_show_outdated "brew outdated --verbose" "$STABLE_UPGRADE_INFO" "$MAGNIFY"
check_result=$?

if [[ $check_result -eq 2 ]]; then
    # No outdated packages found
    if [[ "$(uname)" == "Darwin" ]]; then
        # Only ask about greedy on macOS
        printf "%b ${ARROW} ${LIGHT_GREY}${NO_STABLE_CHOICE_PROMPT}${RESET}"
        
        while true; do
            read -r no_stable_choice
            # Default to option 1 if empty
            if [[ -z "$no_stable_choice" ]]; then
                no_stable_choice=1
            fi
            case $no_stable_choice in
                1)
                    # Check greedy outdated packages
                    check_and_show_outdated "brew outdated --greedy --verbose" "$GREEDY_UPGRADE_INFO" "$MAGNIFY"
                    greedy_result=$?
                    if [[ $greedy_result -eq 2 ]]; then
                        # No additional outdated packages
                        upgrade_duration=0
                        printf "%b ${CHECK_MARK} ${GREEN}No packages need upgrading (including pre-release)!${RESET}\n"
                    elif [[ $greedy_result -eq 0 ]]; then
                        # Show package selection for greedy
                        show_package_selection "brew outdated --greedy" "brew upgrade --greedy"
                        selection_result=$?
                        if [[ $selection_result -eq 0 ]]; then
                            # Upgrade all packages with greedy
                            run_brew_command "brew upgrade --greedy" "$UPGRADE_GREEDY_INFO" "$UPGRADE_GREEDY_SUCCESS" "$ERROR_UPGRADE" "$BUBBLE" upgrade_duration 21
                        elif [[ $selection_result -eq 1 ]]; then
                            # Skip upgrade
                            upgrade_duration=0
                            printf "%b ${YELLOW}Upgrade skipped by user.${RESET}\n"
                        fi
                        # If selection_result is 3, individual package was already upgraded
                    fi
                    break
                    ;;
                2)
                    # Skip upgrade
                    upgrade_duration=0
                    printf "%b ${YELLOW}Upgrade skipped by user.${RESET}\n"
                    break
                    ;;
                *)
                    printf "%b ${ERROR_SIGN} ${RED}Invalid choice. Please select 1 or 2.${RESET}\n"
                    printf "%b ${ARROW} ${LIGHT_GREY}${NO_STABLE_CHOICE_PROMPT}${RESET}"
                    ;;
            esac
        done
    else
        # Not macOS, just show no packages message
        upgrade_duration=0
        printf "%b ${CHECK_MARK} ${GREEN}No packages need upgrading!${RESET}\n"
    fi
elif [[ $check_result -eq 0 ]]; then
    # Outdated packages found, ask user what to do
    if [[ "$(uname)" == "Darwin" ]]; then
        printf "%b ${ARROW} ${LIGHT_GREY}${UPGRADE_CHOICE_PROMPT_MACOS}${RESET}"
    else
        printf "%b ${ARROW} ${LIGHT_GREY}${UPGRADE_CHOICE_PROMPT_OTHER}${RESET}"
    fi
    
    while true; do
        read -r upgrade_choice
        # Default to option 1 if empty
        if [[ -z "$upgrade_choice" ]]; then
            upgrade_choice=1
        fi
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS - 2 options
            case $upgrade_choice in
                1)
                    # Upgrade outdated packages
                    show_package_selection "brew outdated" "brew upgrade"
                    selection_result=$?
                    if [[ $selection_result -eq 0 ]]; then
                        # Upgrade all stable packages
                        run_brew_command "brew upgrade" "$UPGRADE_INFO" "$UPGRADE_SUCCESS" "$ERROR_UPGRADE" "$BUBBLE" upgrade_duration 12
                    elif [[ $selection_result -eq 1 ]]; then
                        # Skip upgrade
                        upgrade_duration=0
                        printf "%b ${YELLOW}Upgrade skipped by user.${RESET}\n"
                    fi
                    # If selection_result is 3, individual package was already upgraded
                    break
                    ;;
                2)
                    # Show greedy outdated packages first
                    check_and_show_outdated "brew outdated --greedy --verbose" "$GREEDY_UPGRADE_INFO" "$MAGNIFY"
                    greedy_result=$?
                    if [[ $greedy_result -eq 2 ]]; then
                        # No additional outdated packages with greedy
                        upgrade_duration=0
                        printf "%b ${CHECK_MARK} ${GREEN}No additional packages found with --greedy option.${RESET}\n"
                        printf "%b ${YELLOW}Falling back to upgrading outdated packages only.${RESET}\n"
                        
                        # Proceed with regular outdated packages
                        show_package_selection "brew outdated" "brew upgrade"
                        selection_result=$?
                        if [[ $selection_result -eq 0 ]]; then
                            # Upgrade all stable packages
                            run_brew_command "brew upgrade" "$UPGRADE_INFO" "$UPGRADE_SUCCESS" "$ERROR_UPGRADE" "$BUBBLE" upgrade_duration 12
                        elif [[ $selection_result -eq 1 ]]; then
                            # Skip upgrade
                            upgrade_duration=0
                            printf "%b ${YELLOW}Upgrade skipped by user.${RESET}\n"
                        fi
                    elif [[ $greedy_result -eq 0 ]]; then
                        # Both outdated and greedy packages found, offer choice
                        handle_greedy_selection
                    fi
                    break
                    ;;
                *)
                    printf "%b ${ERROR_SIGN} ${RED}Invalid choice. Please select 1 or 2.${RESET}\n"
                    printf "%b ${ARROW} ${LIGHT_GREY}${UPGRADE_CHOICE_PROMPT_MACOS}${RESET}"
                    ;;
            esac
        else
            # Non-macOS - 1 option
            case $upgrade_choice in
                1)
                    # Upgrade outdated packages
                    show_package_selection "brew outdated" "brew upgrade"
                    selection_result=$?
                    if [[ $selection_result -eq 0 ]]; then
                        # Upgrade all stable packages
                        run_brew_command "brew upgrade" "$UPGRADE_INFO" "$UPGRADE_SUCCESS" "$ERROR_UPGRADE" "$BUBBLE" upgrade_duration 12
                    elif [[ $selection_result -eq 1 ]]; then
                        # Skip upgrade
                        upgrade_duration=0
                        printf "%b ${YELLOW}Upgrade skipped by user.${RESET}\n"
                    fi
                    # If selection_result is 3, individual package was already upgraded
                    break
                    ;;
                *)
                    printf "%b ${ERROR_SIGN} ${RED}Invalid choice. Please select 1.${RESET}\n"
                    printf "%b ${ARROW} ${LIGHT_GREY}${UPGRADE_CHOICE_PROMPT_OTHER}${RESET}"
                    ;;
            esac
        fi
    done
fi

run_brew_command "brew cleanup" "$CLEANUP_INFO" "$CLEANUP_SUCCESS" "$ERROR_CLEANUP" "$SPONGE" cleanup_duration 15

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
