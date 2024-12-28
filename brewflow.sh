#!/bin/bash

CYAN='\033[0;36m'
DARK_GREEN='\033[0;32m'
RESET='\033[0m'
YELLOW='\033[0;33m'
RED='\033[0;31m'

CHECK_MARK="✅"
CLEANING="🧹"
PACKAGE="📦"
ROCKET="🚀"
WARNING="⚠️"
WRENCH="🔧"

printf "${RED}${WARNING} WARNING: This tool uses brew update, brew upgrade, and brew cleanup. By running it, you accept responsibility for any risks that may arise. Proceed with caution!${RESET}\n"

while true; do
    read -p "Press Enter to continue or Cmd+C to abort... " input
    if [ -z "$input" ]; then
        break
    fi
done

clear

printf "${CYAN}${ROCKET} Welcome to BrewFlow!${RESET}\n"

TOTAL_TIME=0

printf "${CYAN}${PACKAGE} (brew update) ${YELLOW}Fetching Homebrew and package information...${RESET}\n"
START_TIME=$(date +%s)
brew update
END_TIME=$(date +%s)
DIFF_TIME=$((END_TIME - START_TIME))
TOTAL_TIME=$((TOTAL_TIME + DIFF_TIME))
printf "${DARK_GREEN}${CHECK_MARK} Brew update completed in ${DIFF_TIME} seconds!${RESET}\n"

printf "${CYAN}${WRENCH} (brew upgrade) ${YELLOW}Upgrading outdated packages...${RESET}\n"
START_TIME=$(date +%s)
brew upgrade
END_TIME=$(date +%s)
DIFF_TIME=$((END_TIME - START_TIME))
TOTAL_TIME=$((TOTAL_TIME + DIFF_TIME))
printf "${DARK_GREEN}${CHECK_MARK} Brew upgrade completed in ${DIFF_TIME} seconds!${RESET}\n"

printf "${CYAN}${CLEANING} (brew cleanup) ${YELLOW}Cleaning up unnecessary files...${RESET}\n"
START_TIME=$(date +%s)
brew cleanup
END_TIME=$(date +%s)
DIFF_TIME=$((END_TIME - START_TIME))
TOTAL_TIME=$((TOTAL_TIME + DIFF_TIME))
printf "${DARK_GREEN}${CHECK_MARK} Brew cleanup completed in ${DIFF_TIME} seconds!${RESET}\n"

printf "${CYAN}${CHECK_MARK} All processes completed in ${TOTAL_TIME} seconds!${RESET}\n"