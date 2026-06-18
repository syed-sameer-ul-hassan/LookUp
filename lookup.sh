#!/usr/bin/env bash

#  LookUp: Professional Storage Intelligence & Directory Analysis Platform
#  Version: 1.0.0
#  License: Apache 2.0
#  Author:  Syed Sameer Ul Hassan 
#  Requires: Bash 5+, standard Linux utilities

set -euo pipefail

readonly LOOKUP_VERSION="2.0.0"
readonly LOOKUP_NAME="LookUp"
readonly LOOKUP_TAGLINE="Understand Your Files. Clean Your Storage."

readonly LOOKUP_BASE_DIR="${HOME}/.lookup"
readonly LOOKUP_CONFIG_DIR="${LOOKUP_BASE_DIR}/config"
readonly LOOKUP_HISTORY_DIR="${LOOKUP_BASE_DIR}/history"
readonly LOOKUP_SNAPSHOTS_DIR="${LOOKUP_BASE_DIR}/snapshots"
readonly LOOKUP_REPORTS_DIR="${LOOKUP_BASE_DIR}/reports"
readonly LOOKUP_CACHE_DIR="${LOOKUP_BASE_DIR}/cache"
readonly LOOKUP_PLUGINS_DIR="${LOOKUP_BASE_DIR}/plugins"
readonly LOOKUP_LOCKS_DIR="${LOOKUP_BASE_DIR}/locks"

readonly LOOKUP_CONFIG_FILE="${LOOKUP_CONFIG_DIR}/lookup.conf"
readonly LOOKUP_HISTORY_DB="${LOOKUP_HISTORY_DIR}/history.db"
readonly LOOKUP_FAVORITES_FILE="${LOOKUP_CONFIG_DIR}/favorites.lst"
readonly LOOKUP_BOOKMARKS_FILE="${LOOKUP_CONFIG_DIR}/bookmarks.lst"
readonly LOOKUP_PROFILE_FILE="${LOOKUP_CONFIG_DIR}/profile.conf"
readonly LOOKUP_THEME_FILE="${LOOKUP_CONFIG_DIR}/theme.conf"

LOOKUP_TMP_DIR=""
SCAN_TARGET=""
SCAN_ID=""
SCAN_START_TIME=0
SCAN_TOTAL_FILES=0
SCAN_TOTAL_DIRS=0
SCAN_TOTAL_SIZE=0
SCAN_HEALTH_SCORE=0
CURRENT_THEME="dark"
INTERACTIVE=true
QUIET=false
VERBOSE=false
OUTPUT_DIR=""
REPORT_PDF=""
REPORT_HTML=""
REPORT_JSON=""
REPORT_CSV=""
REPORT_TXT=""

apply_theme_dark() {
    C_RESET="\033[0m"
    C_BOLD="\033[1m"
    C_DIM="\033[2m"
    C_ITALIC="\033[3m"
    C_UNDERLINE="\033[4m"

    C_BLACK="\033[30m"
    C_RED="\033[31m"
    C_GREEN="\033[32m"
    C_YELLOW="\033[33m"
    C_BLUE="\033[34m"
    C_MAGENTA="\033[35m"
    C_CYAN="\033[36m"
    C_WHITE="\033[37m"

    C_BG_BLACK="\033[40m"
    C_BG_RED="\033[41m"
    C_BG_GREEN="\033[42m"
    C_BG_YELLOW="\033[43m"
    C_BG_BLUE="\033[44m"
    C_BG_MAGENTA="\033[45m"
    C_BG_CYAN="\033[46m"

    C_BRIGHT_BLACK="\033[90m"
    C_BRIGHT_RED="\033[91m"
    C_BRIGHT_GREEN="\033[92m"
    C_BRIGHT_YELLOW="\033[93m"
    C_BRIGHT_BLUE="\033[94m"
    C_BRIGHT_MAGENTA="\033[95m"
    C_BRIGHT_CYAN="\033[96m"
    C_BRIGHT_WHITE="\033[97m"

    T_TITLE="${C_BRIGHT_CYAN}${C_BOLD}"
    T_HEADER="${C_BRIGHT_BLUE}${C_BOLD}"
    T_LABEL="${C_BRIGHT_WHITE}${C_BOLD}"
    T_VALUE="${C_BRIGHT_YELLOW}"
    T_GOOD="${C_BRIGHT_GREEN}"
    T_WARN="${C_BRIGHT_YELLOW}"
    T_ERROR="${C_BRIGHT_RED}"
    T_INFO="${C_BRIGHT_CYAN}"
    T_DIM="${C_BRIGHT_BLACK}"
    T_BORDER="${C_BRIGHT_BLACK}"
    T_ACCENT="${C_BRIGHT_MAGENTA}"
    T_HIGHLIGHT="${C_BG_BLUE}${C_BRIGHT_WHITE}"
    T_MENU_SEL="${C_BG_CYAN}${C_BLACK}${C_BOLD}"
    T_SCORE_EXCELLENT="${C_BRIGHT_GREEN}${C_BOLD}"
    T_SCORE_GOOD="${C_GREEN}${C_BOLD}"
    T_SCORE_AVG="${C_BRIGHT_YELLOW}${C_BOLD}"
    T_SCORE_POOR="${C_BRIGHT_RED}${C_BOLD}"
}

apply_theme_light() {
    C_RESET="\033[0m"
    C_BOLD="\033[1m"
    C_DIM="\033[2m"
    C_ITALIC="\033[3m"
    C_UNDERLINE="\033[4m"

    C_BLACK="\033[30m"
    C_RED="\033[31m"
    C_GREEN="\033[32m"
    C_YELLOW="\033[33m"
    C_BLUE="\033[34m"
    C_MAGENTA="\033[35m"
    C_CYAN="\033[36m"
    C_WHITE="\033[37m"

    T_TITLE="${C_BLUE}${C_BOLD}"
    T_HEADER="${C_BLUE}${C_BOLD}"
    T_LABEL="${C_BLACK}${C_BOLD}"
    T_VALUE="${C_MAGENTA}${C_BOLD}"
    T_GOOD="${C_GREEN}${C_BOLD}"
    T_WARN="${C_YELLOW}${C_BOLD}"
    T_ERROR="${C_RED}${C_BOLD}"
    T_INFO="${C_CYAN}"
    T_DIM="${C_BLACK}"
    T_BORDER="${C_BLACK}"
    T_ACCENT="${C_MAGENTA}"
    T_HIGHLIGHT="${C_CYAN}${C_BOLD}"
    T_MENU_SEL="${C_BLUE}${C_BOLD}"
    T_SCORE_EXCELLENT="${C_GREEN}${C_BOLD}"
    T_SCORE_GOOD="${C_GREEN}"
    T_SCORE_AVG="${C_YELLOW}${C_BOLD}"
    T_SCORE_POOR="${C_RED}${C_BOLD}"

    C_BRIGHT_BLACK="\033[90m"
    C_BRIGHT_RED="\033[91m"
    C_BRIGHT_GREEN="\033[92m"
    C_BRIGHT_YELLOW="\033[93m"
    C_BRIGHT_BLUE="\033[94m"
    C_BRIGHT_MAGENTA="\033[95m"
    C_BRIGHT_CYAN="\033[96m"
    C_BRIGHT_WHITE="\033[97m"
}

load_theme() {
    if [[ -f "${LOOKUP_THEME_FILE}" ]]; then
        source "${LOOKUP_THEME_FILE}" 2>/dev/null || true
    fi
    if [[ "${CURRENT_THEME}" == "light" ]]; then
        apply_theme_light
    else
        apply_theme_dark
    fi
}

get_terminal_width() {
    tput cols 2>/dev/null || echo 80
}

get_terminal_height() {
    tput lines 2>/dev/null || echo 24
}

clear_screen() {
    printf "\033[2J\033[H"
}

move_cursor() {
    printf "\033[%d;%dH" "$1" "$2"
}

hide_cursor() { printf "\033[?25l"; }
show_cursor() { printf "\033[?25h"; }

print_line() {
    local width="${1:-$(get_terminal_width)}"
    local char="${2:-─}"
    local color="${3:-${T_BORDER}}"
    printf "${color}"
    printf '%*s' "${width}" '' | tr ' ' "${char}"
    printf "${C_RESET}\n"
}

print_dline() {
    local width="${1:-$(get_terminal_width)}"
    local color="${2:-${T_BORDER}}"
    printf "${color}"
    printf '%*s' "${width}" '' | tr ' ' '═'
    printf "${C_RESET}\n"
}

center_text() {
    local text="$1"
    local width="${2:-$(get_terminal_width)}"
    local clean
    clean=$(echo -e "${text}" | sed 's/\x1B\[[0-9;]*[mK]//g')
    local len=${#clean}
    local pad=$(( (width - len) / 2 ))
    printf "%${pad}s%b\n" "" "${text}"
}

pad_right() {
    local text="$1"
    local width="$2"
    local clean
    clean=$(echo -e "${text}" | sed 's/\x1B\[[0-9;]*[mK]//g')
    local len=${#clean}
    local pad=$(( width - len ))
    printf "%b%${pad}s" "${text}" ""
}

human_size() {
    local bytes="${1:-0}"
    if   (( bytes >= 1099511627776 )); then printf "%.2f TB" "$(echo "scale=2; ${bytes}/1099511627776" | bc)"
    elif (( bytes >= 1073741824    )); then printf "%.2f GB" "$(echo "scale=2; ${bytes}/1073741824" | bc)"
    elif (( bytes >= 1048576       )); then printf "%.2f MB" "$(echo "scale=2; ${bytes}/1048576" | bc)"
    elif (( bytes >= 1024          )); then printf "%.2f KB" "$(echo "scale=2; ${bytes}/1024" | bc)"
    else printf "%d B" "${bytes}"
    fi
}

human_duration() {
    local secs="${1:-0}"
    local h=$(( secs / 3600 ))
    local m=$(( (secs % 3600) / 60 ))
    local s=$(( secs % 60 ))
    if   (( h > 0 )); then printf "%dh %dm %ds" "${h}" "${m}" "${s}"
    elif (( m > 0 )); then printf "%dm %ds" "${m}" "${s}"
    else printf "%ds" "${s}"
    fi
}

timestamp_now() {
    date '+%Y-%m-%d %H:%M:%S'
}

epoch_now() {
    date '+%s'
}

generate_id() {
    date '+%Y%m%d_%H%M%S'_$$
}

log_error() {
    printf "${T_ERROR}[ERROR]${C_RESET} %s\n" "$*" >&2
}

log_warn() {
    printf "${T_WARN}[WARN]${C_RESET}  %s\n" "$*"
}

log_info() {
    [[ "${VERBOSE}" == "true" ]] && printf "${T_INFO}[INFO]${C_RESET}  %s\n" "$*"
}

die() {
    log_error "$*"
    show_cursor
    cleanup_tmp
    exit 1
}

cleanup_tmp() {
    if [[ -n "${LOOKUP_TMP_DIR}" && -d "${LOOKUP_TMP_DIR}" ]]; then
        rm -rf "${LOOKUP_TMP_DIR}"
    fi
}

trap 'show_cursor; cleanup_tmp; exit 130' INT TERM

require_cmd() {
    local cmd="$1"
    command -v "${cmd}" &>/dev/null || die "Required command not found: ${cmd}. Please install it."
}

check_dependencies() {
    local missing=()
    local required=(find stat sort awk sed grep cut tr wc date sha256sum du df tput)
    for cmd in "${required[@]}"; do
        command -v "${cmd}" &>/dev/null || missing+=("${cmd}")
    done
    if (( ${#missing[@]} > 0 )); then
        log_warn "Missing optional/required commands: ${missing[*]}"
        log_warn "Some features may be unavailable."
    fi
    command -v wkhtmltopdf &>/dev/null && HAS_WKHTMLTOPDF=true || HAS_WKHTMLTOPDF=false
    command -v enscript    &>/dev/null && HAS_ENSCRIPT=true    || HAS_ENSCRIPT=false
    command -v pandoc      &>/dev/null && HAS_PANDOC=true       || HAS_PANDOC=false
    command -v notify-send &>/dev/null && HAS_NOTIFY=true       || HAS_NOTIFY=false
    command -v bc          &>/dev/null && HAS_BC=true           || HAS_BC=false
}


init_directories() {
    local dirs=(
        "${LOOKUP_BASE_DIR}"
        "${LOOKUP_CONFIG_DIR}"
        "${LOOKUP_HISTORY_DIR}"
        "${LOOKUP_SNAPSHOTS_DIR}"
        "${LOOKUP_REPORTS_DIR}"
        "${LOOKUP_CACHE_DIR}"
        "${LOOKUP_PLUGINS_DIR}"
        "${LOOKUP_LOCKS_DIR}"
    )
    for d in "${dirs[@]}"; do
        mkdir -p "${d}" 2>/dev/null || true
    done
}

init_config() {
    if [[ ! -f "${LOOKUP_CONFIG_FILE}" ]]; then
        cat > "${LOOKUP_CONFIG_FILE}" <<EOF
# LookUp Configuration File
# Generated: $(timestamp_now)

LOOKUP_THEME=dark
LOOKUP_DEFAULT_SCAN_DIR=${HOME}
LOOKUP_REPORT_DIR=${LOOKUP_REPORTS_DIR}
LOOKUP_MAX_HISTORY=50
LOOKUP_LARGE_FILE_MB=100
LOOKUP_FORGOTTEN_MONTHS=6
LOOKUP_HASH_ENABLED=true
LOOKUP_SECURITY_ENABLED=true
LOOKUP_AUTO_REPORT=true
LOOKUP_NOTIFY_ENABLED=false
LOOKUP_MAX_THREADS=4
LOOKUP_SHOW_HIDDEN=false
EOF
    fi
}

load_config() {
    if [[ -f "${LOOKUP_CONFIG_FILE}" ]]; then
      
        source "${LOOKUP_CONFIG_FILE}" 2>/dev/null || true
        CURRENT_THEME="${LOOKUP_THEME:-dark}"
        OUTPUT_DIR="${LOOKUP_REPORT_DIR:-${LOOKUP_REPORTS_DIR}}"
    fi
}

init_history_db() {
    if [[ ! -f "${LOOKUP_HISTORY_DB}" ]]; then
        cat > "${LOOKUP_HISTORY_DB}" <<EOF
# LookUp Scan History Database
# Format: ID|DATE|PATH|FILES|DIRS|SIZE_BYTES|DUPLICATES|HEALTH_SCORE|REPORT_DIR
EOF
    fi
}

first_run_wizard() {
    clear_screen
    print_banner
    echo ""
    printf "${T_TITLE}  Welcome to LookUp! First-Time Setup${C_RESET}\n\n"
    print_line
    printf "  This wizard will configure LookUp for your system.\n\n"

  
    printf "  ${T_LABEL}Default scan directory${C_RESET} [${HOME}]: "
    read -r default_dir
    default_dir="${default_dir:-${HOME}}"

  
    printf "  ${T_LABEL}Theme${C_RESET} (dark/light) [dark]: "
    read -r theme
    theme="${theme:-dark}"

  
    printf "  ${T_LABEL}Reports output directory${C_RESET} [${LOOKUP_REPORTS_DIR}]: "
    read -r report_dir
    report_dir="${report_dir:-${LOOKUP_REPORTS_DIR}}"
    mkdir -p "${report_dir}" 2>/dev/null || true

    cat > "${LOOKUP_CONFIG_FILE}" <<EOF
# LookUp Configuration File
# Generated: $(timestamp_now)

LOOKUP_THEME=${theme}
LOOKUP_DEFAULT_SCAN_DIR=${default_dir}
LOOKUP_REPORT_DIR=${report_dir}
LOOKUP_MAX_HISTORY=50
LOOKUP_LARGE_FILE_MB=100
LOOKUP_FORGOTTEN_MONTHS=6
LOOKUP_HASH_ENABLED=true
LOOKUP_SECURITY_ENABLED=true
LOOKUP_AUTO_REPORT=true
LOOKUP_NOTIFY_ENABLED=false
LOOKUP_MAX_THREADS=4
LOOKUP_SHOW_HIDDEN=false
EOF

    printf "\n  ${T_GOOD}✔ Configuration saved.${C_RESET}\n"
    sleep 1
}

init_all() {
    init_directories
    init_config
    load_config
    load_theme
    init_history_db
    LOOKUP_TMP_DIR=$(mktemp -d /tmp/lookup_XXXXXX)
    check_dependencies
    OUTPUT_DIR="${LOOKUP_REPORT_DIR:-${LOOKUP_REPORTS_DIR}}"
    mkdir -p "${OUTPUT_DIR}" 2>/dev/null || true
}

print_banner() {
    local width
    width=$(get_terminal_width)

    printf "${T_TITLE}"
    cat <<'BANNER'

@@            @@@@@@      @@@@@@    @@      @@        @@      @@  @@@@@@@@    
@@            @@@@@@      @@@@@@    @@      @@        @@      @@  @@@@@@@@    
@@          @@      @@  @@      @@  @@    @@          @@      @@  @@      @@  
@@          @@      @@  @@      @@  @@    @@          @@      @@  @@      @@  
@@          @@      @@  @@      @@  @@@@@@            @@      @@  @@@@@@@@    
@@          @@      @@  @@      @@  @@@@@@            @@      @@  @@@@@@@@    
@@          @@      @@  @@      @@  @@    @@          @@      @@  @@          
@@          @@      @@  @@      @@  @@    @@          @@      @@  @@          
@@@@@@@@@@    @@@@@@      @@@@@@    @@      @@          @@@@@@    @@          
@@@@@@@@@@    @@@@@@      @@@@@@    @@      @@          @@@@@@    @@          

BANNER
    printf "${C_RESET}"
    center_text "${T_ACCENT}${LOOKUP_TAGLINE}${C_RESET}" "${width}"
    printf "\n"

    local os_name kernel_ver
    os_name=$(uname -s 2>/dev/null || echo "Linux")
    kernel_ver=$(uname -r 2>/dev/null || echo "unknown")

    printf "  ${T_DIM}Version:${C_RESET} ${T_VALUE}v${LOOKUP_VERSION}${C_RESET}   "
    printf "${T_DIM}User:${C_RESET} ${T_VALUE}${USER:-$(whoami)}${C_RESET}   "
    printf "${T_DIM}Host:${C_RESET} ${T_VALUE}$(hostname 2>/dev/null || echo 'unknown')${C_RESET}   "
    printf "${T_DIM}OS:${C_RESET} ${T_VALUE}${os_name}${C_RESET}   "
    printf "${T_DIM}Kernel:${C_RESET} ${T_VALUE}${kernel_ver}${C_RESET}\n"
    printf "  ${T_DIM}Date:${C_RESET}  ${T_VALUE}$(timestamp_now)${C_RESET}   "
    printf "${T_DIM}CWD:${C_RESET} ${T_VALUE}$(pwd)${C_RESET}\n"
    print_dline "${width}"
}

print_section_header() {
    local title="$1"
    local width="${2:-$(get_terminal_width)}"
    printf "\n"
    print_line "${width}" "─"
    printf "  ${T_HEADER}▸ %s${C_RESET}\n" "${title}"
    print_line "${width}" "─"
}

draw_progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-40}"
    local pct=0
    [[ "${total}" -gt 0 ]] && pct=$(( current * 100 / total ))
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    printf "${T_GOOD}["
    printf '%*s' "${filled}" '' | tr ' ' '█'
    printf '%*s' "${empty}"  '' | tr ' ' '░'
    printf "]${C_RESET} ${T_VALUE}%3d%%${C_RESET}" "${pct}"
}

draw_mini_bar() {
    local value="$1"   
    local width="${2:-20}"
    local color="${3:-${T_GOOD}}"
    local filled=$(( value * width / 100 ))
    local empty=$(( width - filled ))
    printf "${color}"
    printf '%*s' "${filled}" '' | tr ' ' '█'
    printf "${T_DIM}"
    printf '%*s' "${empty}"  '' | tr ' ' '░'
    printf "${C_RESET}"
}

score_color() {
    local score="$1"
    if   (( score >= 90 )); then printf "%b" "${T_SCORE_EXCELLENT}"
    elif (( score >= 70 )); then printf "%b" "${T_SCORE_GOOD}"
    elif (( score >= 50 )); then printf "%b" "${T_SCORE_AVG}"
    else                         printf "%b" "${T_SCORE_POOR}"
    fi
}

score_label() {
    local score="$1"
    if   (( score >= 90 )); then echo "Excellent"
    elif (( score >= 70 )); then echo "Good"
    elif (( score >= 50 )); then echo "Average"
    else                         echo "Poor"
    fi
}


TMP_FILES_LIST=""
TMP_DIRS_LIST=""
TMP_SIZES_LIST=""
TMP_HASHES_FILE=""
TMP_DUPLICATES_FILE=""
TMP_LARGE_FILES=""
TMP_OLD_FILES=""
TMP_EMPTY_FILES=""
TMP_EMPTY_DIRS=""
TMP_SECURITY_FILE=""
TMP_EXT_STATS=""
TMP_AGE_STATS=""
TMP_PERMS_FILE=""

init_scan_files() {
    TMP_FILES_LIST="${LOOKUP_TMP_DIR}/files.list"
    TMP_DIRS_LIST="${LOOKUP_TMP_DIR}/dirs.list"
    TMP_SIZES_LIST="${LOOKUP_TMP_DIR}/sizes.list"
    TMP_HASHES_FILE="${LOOKUP_TMP_DIR}/hashes.lst"
    TMP_DUPLICATES_FILE="${LOOKUP_TMP_DIR}/duplicates.lst"
    TMP_LARGE_FILES="${LOOKUP_TMP_DIR}/large.lst"
    TMP_OLD_FILES="${LOOKUP_TMP_DIR}/old.lst"
    TMP_EMPTY_FILES="${LOOKUP_TMP_DIR}/empty_files.lst"
    TMP_EMPTY_DIRS="${LOOKUP_TMP_DIR}/empty_dirs.lst"
    TMP_SECURITY_FILE="${LOOKUP_TMP_DIR}/security.lst"
    TMP_EXT_STATS="${LOOKUP_TMP_DIR}/ext_stats.lst"
    TMP_AGE_STATS="${LOOKUP_TMP_DIR}/age_stats.lst"
    TMP_PERMS_FILE="${LOOKUP_TMP_DIR}/perms.lst"
    > "${TMP_FILES_LIST}"
    > "${TMP_DIRS_LIST}"
    > "${TMP_SIZES_LIST}"
    > "${TMP_HASHES_FILE}"
    > "${TMP_DUPLICATES_FILE}"
    > "${TMP_LARGE_FILES}"
    > "${TMP_OLD_FILES}"
    > "${TMP_EMPTY_FILES}"
    > "${TMP_EMPTY_DIRS}"
    > "${TMP_SECURITY_FILE}"
    > "${TMP_EXT_STATS}"
    > "${TMP_AGE_STATS}"
    > "${TMP_PERMS_FILE}"
}

run_scan() {
    local target="$1"
    SCAN_TARGET="$(realpath "${target}" 2>/dev/null || echo "${target}")"
    SCAN_ID=$(generate_id)
    SCAN_START_TIME=$(epoch_now)

    [[ -d "${SCAN_TARGET}" ]] || die "Not a directory: ${SCAN_TARGET}"

    init_scan_files

    clear_screen
    print_banner
    print_section_header "LIVE SCAN ─ ${SCAN_TARGET}"

    printf "\n  ${T_INFO}Collecting file list...${C_RESET}\n"

    local find_opts=(-type f)
    [[ "${LOOKUP_SHOW_HIDDEN:-false}" == "false" ]] && find_opts+=( ! -name '.*' )

    find "${SCAN_TARGET}" "${find_opts[@]}" -print0 2>/dev/null \
        | tr '\0' '\n' > "${TMP_FILES_LIST}" || true

    # Gather all dirs
    find "${SCAN_TARGET}" -type d -print0 2>/dev/null \
        | tr '\0' '\n' > "${TMP_DIRS_LIST}" || true

    SCAN_TOTAL_FILES=$(wc -l < "${TMP_FILES_LIST}" 2>/dev/null || echo 0)
    SCAN_TOTAL_DIRS=$(wc -l < "${TMP_DIRS_LIST}" 2>/dev/null || echo 0)
    SCAN_TOTAL_FILES="${SCAN_TOTAL_FILES// /}"
    SCAN_TOTAL_DIRS="${SCAN_TOTAL_DIRS// /}"

    printf "  ${T_LABEL}Files found:${C_RESET} ${T_VALUE}%s${C_RESET}   ${T_LABEL}Dirs:${C_RESET} ${T_VALUE}%s${C_RESET}\n\n" \
        "${SCAN_TOTAL_FILES}" "${SCAN_TOTAL_DIRS}"

  
    _scan_phase_stat

  
    _scan_phase_hashes

  
    _scan_phase_analysis

    local scan_end
    scan_end=$(epoch_now)
    local duration=$(( scan_end - SCAN_START_TIME ))

    printf "\n  ${T_GOOD}✔ Scan complete in $(human_duration ${duration})${C_RESET}\n\n"
}

_scan_phase_stat() {
    local total="${SCAN_TOTAL_FILES}"
    local done_count=0
    local last_update=0
    local now

    printf "  ${T_HEADER}Phase 1/3: Analyzing files...${C_RESET}\n\n"
    hide_cursor

    SCAN_TOTAL_SIZE=0
    local tmp_size="${LOOKUP_TMP_DIR}/sizes_raw.lst"
    > "${tmp_size}"

    while IFS= read -r filepath; do
        [[ -f "${filepath}" ]] || continue

      
        local size mtime atime perms owner group
        read -r size mtime perms owner group < <(
            stat -c '%s %Y %a %U %G' "${filepath}" 2>/dev/null || echo "0 0 000 unknown unknown"
        )
        atime=$(stat -c '%X' "${filepath}" 2>/dev/null || echo "0")

        local ext="${filepath##*.}"
        [[ "${filepath}" == "${ext}" ]] && ext="none"
        ext="${ext,,}"

        echo "${filepath}|${size}|${mtime}|${atime}|${perms}|${owner}|${group}|${ext}" >> "${TMP_SIZES_LIST}"
        echo "${size}" >> "${tmp_size}"
        echo "${size} ${filepath}" >> "${TMP_LARGE_FILES}_raw"

        (( done_count++ ))
        now=$(epoch_now)

      
        if (( done_count % 50 == 0 || done_count == total )); then
            local elapsed=$(( now - SCAN_START_TIME ))
            local speed=0
            [[ "${elapsed}" -gt 0 ]] && speed=$(( done_count / elapsed ))
            local eta=0
            [[ "${speed}" -gt 0 ]] && eta=$(( (total - done_count) / speed ))

            printf "\r  "
            draw_progress_bar "${done_count}" "${total}" 45
            printf "  ${T_DIM}Files: ${T_VALUE}%d${T_DIM}/%d  Speed: ${T_VALUE}%d/s${T_DIM}  ETA: ${T_VALUE}%s${C_RESET}  " \
                "${done_count}" "${total}" "${speed}" "$(human_duration ${eta})"
        fi

    done < "${TMP_FILES_LIST}"

    printf "\n"
    show_cursor

    if [[ -f "${tmp_size}" ]]; then
        SCAN_TOTAL_SIZE=$(awk '{s+=$1}END{print s+0}' "${tmp_size}")
    fi
    
    if [[ -f "${TMP_LARGE_FILES}_raw" ]]; then
        sort -rn "${TMP_LARGE_FILES}_raw" | head -50 > "${TMP_LARGE_FILES}"
        rm -f "${TMP_LARGE_FILES}_raw"
    fi

    
    awk -F'|' '$2==0{print $1}' "${TMP_SIZES_LIST}" > "${TMP_EMPTY_FILES}" 2>/dev/null || true

    
    while IFS= read -r d; do
        [[ -d "${d}" ]] || continue
        local cnt
        cnt=$(find "${d}" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
        [[ "${cnt// /}" -eq 0 ]] && echo "${d}" >> "${TMP_EMPTY_DIRS}"
    done < "${TMP_DIRS_LIST}"

  
    local now_epoch
    now_epoch=$(epoch_now)
    awk -F'|' -v now="${now_epoch}" '
    {
        age_days = int((now - $3) / 86400)
        if (age_days >= 180) print $1 "|" age_days "|" $2
    }' "${TMP_SIZES_LIST}" | sort -t'|' -k2 -rn > "${TMP_OLD_FILES}" 2>/dev/null || true
}

_scan_phase_hashes() {
    local total="${SCAN_TOTAL_FILES}"

    [[ "${LOOKUP_HASH_ENABLED:-true}" != "true" ]] && return

    printf "\n  ${T_HEADER}Phase 2/3: Computing hashes for duplicate detection...${C_RESET}\n"
    hide_cursor

    local done_count=0
    
    while IFS='|' read -r filepath size rest; do
        [[ -f "${filepath}" ]] || continue
        (( size > 524288000 )) && { (( done_count++ )); continue; }

        local hash
        hash=$(sha256sum "${filepath}" 2>/dev/null | cut -d' ' -f1)
        [[ -n "${hash}" ]] && echo "${hash} ${filepath}" >> "${TMP_HASHES_FILE}"

        (( done_count++ ))
        if (( done_count % 100 == 0 || done_count == total )); then
            printf "\r  "
            draw_progress_bar "${done_count}" "${total}" 45
            printf "  ${T_DIM}Hashed: ${T_VALUE}%d${C_RESET}  " "${done_count}"
        fi
    done < <(awk -F'|' '{print $1 "|" $2 "|"}' "${TMP_SIZES_LIST}")

    printf "\n"
    show_cursor

    if [[ -s "${TMP_HASHES_FILE}" ]]; then
        sort "${TMP_HASHES_FILE}" | \
            awk '{
                hash=$1; $1=""; path=substr($0,2)
                if (seen[hash]) {
                    print hash " " path
                }
                seen[hash]=1
            }' > "${TMP_DUPLICATES_FILE}" 2>/dev/null || true
    fi
}

_scan_phase_analysis() {
    printf "\n  ${T_HEADER}Phase 3/3: Running analysis...${C_RESET}\n"

    local now_epoch
    now_epoch=$(epoch_now)

    while IFS='|' read -r filepath size mtime atime perms owner group ext; do
        [[ -f "${filepath}" ]] || continue

        local mode_oct="${perms}"
        local last_digit="${mode_oct: -1}"
        if (( last_digit >= 2 && last_digit % 2 == 0 )) 2>/dev/null; then
            echo "WORLD_WRITABLE|${filepath}|${perms}" >> "${TMP_SECURITY_FILE}"
        fi

        local basename="${filepath##*/}"
        if echo "${basename}" | grep -qE '\.[a-zA-Z0-9]+\.(exe|bat|cmd|sh|ps1|vbs|js|py|rb|pl)$' 2>/dev/null; then
            echo "DOUBLE_EXT|${filepath}|${basename}" >> "${TMP_SECURITY_FILE}"
        fi


        if [[ -x "${filepath}" ]] && [[ "${ext}" != "sh" ]] && \
           echo "${filepath}" | grep -qv '/bin/\|/sbin/\|/usr/' 2>/dev/null; then
            echo "UNUSUAL_EXEC|${filepath}|${perms}" >> "${TMP_SECURITY_FILE}"
        fi

    
        echo "${filepath}|${perms}|${owner}|${group}" >> "${TMP_PERMS_FILE}"

    done < "${TMP_SIZES_LIST}"

    awk -F'|' '{
        ext=$8; size=$2
        ext_count[ext]++
        ext_size[ext]+=size
    }
    END{
        for(e in ext_count) print ext_count[e] " " ext_size[e] " " e
    }' "${TMP_SIZES_LIST}" | sort -rn > "${TMP_EXT_STATS}" 2>/dev/null || true

    awk -F'|' -v now="${now_epoch}" '
    {
        age_days = int((now - $3) / 86400)
        if      (age_days == 0)          bucket="today"
        else if (age_days <= 7)          bucket="week"
        else if (age_days <= 30)         bucket="month"
        else if (age_days <= 90)         bucket="3months"
        else if (age_days <= 365)        bucket="year"
        else if (age_days <= 1095)       bucket="1_3years"
        else if (age_days <= 1825)       bucket="3_5years"
        else if (age_days <= 3650)       bucket="5_10years"
        else                             bucket="10plus"
        age_count[bucket]++
        age_size[bucket]+=$2
    }
    END{
        for(b in age_count) print b " " age_count[b] " " age_size[b]
    }' "${TMP_SIZES_LIST}" > "${TMP_AGE_STATS}" 2>/dev/null || true

  
    _calculate_health_score
}

_calculate_health_score() {
    local score=100
    local total="${SCAN_TOTAL_FILES}"
    [[ "${total}" -eq 0 ]] && { SCAN_HEALTH_SCORE=100; return; }


    local dup_count
    dup_count=$(wc -l < "${TMP_DUPLICATES_FILE}" 2>/dev/null || echo 0)
    dup_count="${dup_count// /}"
    local dup_pct=0
    [[ "${total}" -gt 0 ]] && dup_pct=$(( dup_count * 100 / total ))
    score=$(( score - dup_pct / 2 ))

  
    local empty_count
    empty_count=$(wc -l < "${TMP_EMPTY_FILES}" 2>/dev/null || echo 0)
    empty_count="${empty_count// /}"
    [[ "${empty_count}" -gt 50 ]] && score=$(( score - 5 ))
    [[ "${empty_count}" -gt 200 ]] && score=$(( score - 5 ))

    
    local empty_dirs
    empty_dirs=$(wc -l < "${TMP_EMPTY_DIRS}" 2>/dev/null || echo 0)
    empty_dirs="${empty_dirs// /}"
    [[ "${empty_dirs}" -gt 20 ]] && score=$(( score - 5 ))

    
    local sec_count
    sec_count=$(wc -l < "${TMP_SECURITY_FILE}" 2>/dev/null || echo 0)
    sec_count="${sec_count// /}"
    score=$(( score - sec_count * 2 ))

    
    local old_count
    old_count=$(awk -F'|' '$2>=365' "${TMP_OLD_FILES}" 2>/dev/null | wc -l)
    old_count="${old_count// /}"
    [[ "${total}" -gt 0 ]] && {
        local old_pct=$(( old_count * 100 / total ))
        score=$(( score - old_pct / 4 ))
    }

  
    [[ "${score}" -lt 0   ]] && score=0
    [[ "${score}" -gt 100 ]] && score=100
    SCAN_HEALTH_SCORE="${score}"
}



show_dashboard() {
    clear_screen
    print_banner
    local width
    width=$(get_terminal_width)

    print_section_header "SCAN SUMMARY DASHBOARD"

    local dur=$(( $(epoch_now) - SCAN_START_TIME ))
    local dup_count empty_count empty_dirs sec_count old_count wasted_size

    dup_count=$(wc -l < "${TMP_DUPLICATES_FILE}" 2>/dev/null || echo 0)
    dup_count="${dup_count// /}"
    empty_count=$(wc -l < "${TMP_EMPTY_FILES}" 2>/dev/null || echo 0)
    empty_count="${empty_count// /}"
    empty_dirs=$(wc -l < "${TMP_EMPTY_DIRS}" 2>/dev/null || echo 0)
    empty_dirs="${empty_dirs// /}"
    sec_count=$(wc -l < "${TMP_SECURITY_FILE}" 2>/dev/null || echo 0)
    sec_count="${sec_count// /}"
    old_count=$(awk -F'|' '$2>=365' "${TMP_OLD_FILES}" 2>/dev/null | wc -l || echo 0)
    old_count="${old_count// /}"

    
    wasted_size=0
    if [[ -s "${TMP_DUPLICATES_FILE}" ]]; then
        while IFS=' ' read -r hash path; do
            local fsz
            fsz=$(stat -c '%s' "${path}" 2>/dev/null || echo 0)
            wasted_size=$(( wasted_size + fsz ))
        done < "${TMP_DUPLICATES_FILE}"
    fi

    local largest_file oldest_file largest_path oldest_path
    largest_path=$(head -1 "${TMP_LARGE_FILES}" 2>/dev/null | awk '{print $2}')
    largest_file=$(head -1 "${TMP_LARGE_FILES}" 2>/dev/null | awk '{print $1}')
    oldest_path=$(tail -1 "${TMP_OLD_FILES}" 2>/dev/null | cut -d'|' -f1)

    
    printf "\n"
    local sc="${SCAN_HEALTH_SCORE}"
    local sc_color sc_label
    sc_color=$(score_color "${sc}")
    sc_label=$(score_label "${sc}")

    printf "  ${T_LABEL}Directory Health Score:${C_RESET}  ${sc_color}%3d/100  ▪  %s${C_RESET}  " "${sc}" "${sc_label}"
    draw_mini_bar "${sc}" 30 "${sc_color}"
    printf "\n\n"

    
    local col1=40 col2=40

    _dash_row "📁 Files Scanned"       "${SCAN_TOTAL_FILES}"              \
              "📂 Dirs Scanned"         "${SCAN_TOTAL_DIRS}"
    _dash_row "💾 Total Storage"        "$(human_size ${SCAN_TOTAL_SIZE})" \
              "⏱  Scan Duration"        "$(human_duration ${dur})"
    _dash_row "🔁 Duplicate Files"      "${dup_count}"                     \
              "🗑  Space Wasted"          "$(human_size ${wasted_size})"
    _dash_row "⚠  Security Warnings"   "${sec_count}"                     \
              "🕳  Empty Files"           "${empty_count}"
    _dash_row "📅 Old Files (1yr+)"     "${old_count}"                     \
              "📭 Empty Dirs"            "${empty_dirs}"

    if [[ -n "${largest_path}" ]]; then
        printf "\n  ${T_LABEL}%-22s${C_RESET} ${T_VALUE}%s${C_RESET}\n" \
            "🔍 Largest File:" "$(human_size ${largest_file:-0}) → ${largest_path}"
    fi
    if [[ -n "${oldest_path}" ]]; then
        printf "  ${T_LABEL}%-22s${C_RESET} ${T_VALUE}%s${C_RESET}\n" \
            "🕰  Oldest File:" "${oldest_path}"
    fi

    
    local cleanup_potential=$(( wasted_size + empty_count * 0 ))
    printf "\n  ${T_LABEL}%-22s${C_RESET} ${T_WARN}%s${C_RESET}\n" \
        "🧹 Cleanup Potential:" "$(human_size ${cleanup_potential}) (duplicates alone)"

  
    print_section_header "REPORT LOCATIONS"
    [[ -n "${REPORT_PDF}"  ]] && printf "  ${T_LABEL}📄 PDF Report:${C_RESET}  ${T_INFO}%s${C_RESET}\n" "${REPORT_PDF}"
    [[ -n "${REPORT_HTML}" ]] && printf "  ${T_LABEL}🌐 HTML Report:${C_RESET} ${T_INFO}%s${C_RESET}\n" "${REPORT_HTML}"
    [[ -n "${REPORT_JSON}" ]] && printf "  ${T_LABEL}📋 JSON Report:${C_RESET} ${T_INFO}%s${C_RESET}\n" "${REPORT_JSON}"
    [[ -n "${REPORT_CSV}"  ]] && printf "  ${T_LABEL}📊 CSV Report:${C_RESET}  ${T_INFO}%s${C_RESET}\n" "${REPORT_CSV}"
    [[ -n "${REPORT_TXT}"  ]] && printf "  ${T_LABEL}📝 TXT Report:${C_RESET}  ${T_INFO}%s${C_RESET}\n" "${REPORT_TXT}"

  
    printf "\n  ${T_DIM}History Entry ID:${C_RESET} ${T_VALUE}%s${C_RESET}\n" "${SCAN_ID}"
    print_dline "${width}"
}

_dash_row() {
    local l1="$1" v1="$2" l2="$3" v2="$4"
    printf "  ${T_LABEL}%-22s${C_RESET} ${T_VALUE}%-18s${C_RESET}  " "${l1}:" "${v1}"
    printf "${T_LABEL}%-22s${C_RESET} ${T_VALUE}%s${C_RESET}\n"    "${l2}:" "${v2}"
}

show_large_files() {
    clear_screen
    print_banner
    print_section_header "TOP 50 LARGEST FILES"
    printf "\n  ${T_LABEL}%-12s  %-70s${C_RESET}\n" "SIZE" "PATH"
    print_line

    local rank=0
    while IFS=' ' read -r size path; do
        (( rank++ ))
        local color="${T_VALUE}"
        (( size >= 5368709120 )) && color="${T_ERROR}"      # 5GB+
        (( size >= 1073741824 && size < 5368709120 )) && color="${T_WARN}"   # 1GB+
        (( size >= 524288000  && size < 1073741824 )) && color="${C_YELLOW}" # 500MB+

        printf "  ${T_DIM}%3d.${C_RESET} ${color}%-12s${C_RESET}  ${T_DIM}%s${C_RESET}\n" \
            "${rank}" "$(human_size ${size})" "${path}"
        [[ "${rank}" -ge 50 ]] && break
    done < "${TMP_LARGE_FILES}"

    printf "\n"
    read -rp "  Press ENTER to continue..." _
}

show_duplicates() {
    clear_screen
    print_banner
    print_section_header "DUPLICATE FILES"

    local dup_count
    dup_count=$(wc -l < "${TMP_DUPLICATES_FILE}" 2>/dev/null || echo 0)
    dup_count="${dup_count// /}"

    printf "\n  ${T_LABEL}Total duplicate files detected:${C_RESET} ${T_VALUE}%s${C_RESET}\n\n" "${dup_count}"

    if [[ "${dup_count}" -eq 0 ]]; then
        printf "  ${T_GOOD}✔ No duplicate files found!${C_RESET}\n\n"
        read -rp "  Press ENTER to continue..." _
        return
    fi

    printf "  ${T_WARN}⚠ These files share identical SHA256 checksums:${C_RESET}\n\n"
    printf "  ${T_LABEL}%-64s  %-12s${C_RESET}\n" "PATH" "SIZE"
    print_line

    local shown=0
    while IFS=' ' read -r hash path; do
        [[ -f "${path}" ]] || continue
        local sz
        sz=$(stat -c '%s' "${path}" 2>/dev/null || echo 0)
        printf "  ${T_DIM}%s${C_RESET}  ${T_VALUE}%s${C_RESET}\n" \
            "${path}" "$(human_size ${sz})"
        (( shown++ ))
        [[ "${shown}" -ge 100 ]] && { printf "  ${T_DIM}... and more (showing first 100)${C_RESET}\n"; break; }
    done < "${TMP_DUPLICATES_FILE}"

    printf "\n  ${T_WARN}⚠ Files are displayed only. Nothing has been deleted.${C_RESET}\n"
    printf "  ${T_DIM}Use --cleanup flag or menu option to manage safely.${C_RESET}\n\n"
    read -rp "  Press ENTER to continue..." _
}

show_old_files() {
    clear_screen
    print_banner
    print_section_header "OLD & FORGOTTEN FILES"
    printf "\n"

    local categories=(
        "today:0:1:Today"
        "week:1:7:Last Week"
        "month:7:30:Last Month"
        "3months:30:90:Last 3 Months"
        "year:90:365:Last Year"
        "1_3years:365:1095:1–3 Years"
        "3_5years:1095:1825:3–5 Years"
        "5_10years:1825:3650:5–10 Years"
        "10plus:3650:999999:10+ Years"
    )

    printf "  ${T_LABEL}%-20s  %8s  %10s  %6s${C_RESET}\n" "AGE CATEGORY" "FILES" "SIZE" "%"
    print_line

    local total_old=0
    while IFS= read -r line; do
        (( total_old++ ))
    done < "${TMP_OLD_FILES}" 2>/dev/null || true

    [[ "${total_old}" -eq 0 ]] && total_old=1

    for cat in "${categories[@]}"; do
        IFS=':' read -r key min max label <<< "${cat}"
        local count=0 size=0
        while IFS='|' read -r path days sz; do
            [[ -z "${path}" ]] && continue
            if (( days >= min && days < max )); then
                (( count++ ))
                (( size += sz ))
            fi
        done < "${TMP_OLD_FILES}" 2>/dev/null || true

        local pct=0
        [[ "${SCAN_TOTAL_FILES}" -gt 0 ]] && pct=$(( count * 100 / SCAN_TOTAL_FILES ))

        local color="${T_VALUE}"
        (( days >= 1825 )) && color="${T_WARN}"
        (( days >= 3650 )) && color="${T_ERROR}"

        printf "  ${color}%-20s${C_RESET}  ${T_VALUE}%8s${C_RESET}  ${T_VALUE}%10s${C_RESET}  " \
            "${label}" "${count}" "$(human_size ${size})"
        draw_mini_bar "${pct}" 20
        printf " %3d%%\n" "${pct}"
    done

    printf "\n"
    read -rp "  Press ENTER to continue..." _
}

show_security() {
    clear_screen
    print_banner
    print_section_header "SECURITY ANALYSIS"

    local sec_count
    sec_count=$(wc -l < "${TMP_SECURITY_FILE}" 2>/dev/null || echo 0)
    sec_count="${sec_count// /}"

    printf "\n  ${T_LABEL}Security issues detected:${C_RESET} "
    if [[ "${sec_count}" -eq 0 ]]; then
        printf "${T_GOOD}None${C_RESET}\n\n"
    else
        printf "${T_ERROR}%s${C_RESET}\n\n" "${sec_count}"
    fi

    if [[ "${sec_count}" -gt 0 ]]; then
        printf "  ${T_LABEL}%-20s  %-60s  %s${C_RESET}\n" "TYPE" "PATH" "DETAIL"
        print_line

        while IFS='|' read -r type path detail; do
            local color="${T_WARN}"
            local icon="⚠"
            case "${type}" in
                DOUBLE_EXT)     color="${T_ERROR}"; icon="🚨";;
                WORLD_WRITABLE) color="${T_WARN}";  icon="⚠";;
                UNUSUAL_EXEC)   color="${T_WARN}";  icon="⚡";;
            esac
            printf "  ${color}%s %-18s${C_RESET}  ${T_DIM}%-60s${C_RESET}  ${T_VALUE}%s${C_RESET}\n" \
                "${icon}" "${type}" "${path}" "${detail}"
        done < "${TMP_SECURITY_FILE}"
    fi

    printf "\n"
    read -rp "  Press ENTER to continue..." _
}

show_storage_breakdown() {
    clear_screen
    print_banner
    print_section_header "STORAGE BREAKDOWN BY FILE TYPE"

    printf "\n  ${T_LABEL}%-15s  %8s  %12s  %8s  %-25s${C_RESET}\n" \
        "EXTENSION" "COUNT" "SIZE" "%" "BAR"
    print_line

    local shown=0
    while IFS=' ' read -r count size ext; do
        [[ -z "${ext}" ]] && continue
        local pct=0
        [[ "${SCAN_TOTAL_SIZE}" -gt 0 ]] && pct=$(( size * 100 / SCAN_TOTAL_SIZE ))

        printf "  ${T_VALUE}%-15s${C_RESET}  ${T_INFO}%8s${C_RESET}  ${T_VALUE}%12s${C_RESET}  %6d%%  " \
            ".${ext}" "${count}" "$(human_size ${size})" "${pct}"
        draw_mini_bar "${pct}" 25
        printf "\n"
        (( shown++ ))
        [[ "${shown}" -ge 40 ]] && break
    done < "${TMP_EXT_STATS}"

    printf "\n"
    read -rp "  Press ENTER to continue..." _
}

show_cleanup_suggestions() {
    clear_screen
    print_banner
    print_section_header "SMART CLEANUP RECOMMENDATIONS"
    printf "\n"

    local dup_count empty_count empty_dirs old_count wasted_size
    dup_count=$(wc -l < "${TMP_DUPLICATES_FILE}" 2>/dev/null || echo 0)
    dup_count="${dup_count// /}"
    empty_count=$(wc -l < "${TMP_EMPTY_FILES}" 2>/dev/null || echo 0)
    empty_count="${empty_count// /}"
    empty_dirs=$(wc -l < "${TMP_EMPTY_DIRS}" 2>/dev/null || echo 0)
    empty_dirs="${empty_dirs// /}"

    wasted_size=0
    if [[ -s "${TMP_DUPLICATES_FILE}" ]]; then
        while IFS=' ' read -r hash path; do
            local fsz
            fsz=$(stat -c '%s' "${path}" 2>/dev/null || echo 0)
            wasted_size=$(( wasted_size + fsz ))
        done < "${TMP_DUPLICATES_FILE}"
    fi

    local rec_count=0

    if [[ "${dup_count}" -gt 0 ]]; then
        (( rec_count++ ))
        printf "  ${T_ERROR}[${rec_count}]${C_RESET} ${T_LABEL}Remove Duplicate Files${C_RESET}\n"
        printf "      → ${dup_count} duplicate files found, wasting $(human_size ${wasted_size})\n"
        printf "      → Review list in Duplicate Files menu before deleting\n\n"
    fi

    if [[ "${empty_count}" -gt 0 ]]; then
        (( rec_count++ ))
        printf "  ${T_WARN}[${rec_count}]${C_RESET} ${T_LABEL}Delete Empty Files${C_RESET}\n"
        printf "      → ${empty_count} zero-byte files detected\n"
        printf "      → Command: find \"${SCAN_TARGET}\" -empty -type f -delete\n\n"
    fi

    if [[ "${empty_dirs}" -gt 0 ]]; then
        (( rec_count++ ))
        printf "  ${T_WARN}[${rec_count}]${C_RESET} ${T_LABEL}Remove Empty Directories${C_RESET}\n"
        printf "      → ${empty_dirs} empty directories found\n"
        printf "      → Command: find \"${SCAN_TARGET}\" -empty -type d -delete\n\n"
    fi

    local old_count
    old_count=$(awk -F'|' '$2>=365' "${TMP_OLD_FILES}" 2>/dev/null | wc -l || echo 0)
    old_count="${old_count// /}"
    if [[ "${old_count}" -gt 0 ]]; then
        (( rec_count++ ))
        printf "  ${T_INFO}[${rec_count}]${C_RESET} ${T_LABEL}Archive Old Files${C_RESET}\n"
        printf "      → ${old_count} files not modified in over 1 year\n"
        printf "      → Consider archiving to cold storage or external drive\n\n"
    fi

    local sec_count
    sec_count=$(wc -l < "${TMP_SECURITY_FILE}" 2>/dev/null || echo 0)
    sec_count="${sec_count// /}"
    if [[ "${sec_count}" -gt 0 ]]; then
        (( rec_count++ ))
        printf "  ${T_ERROR}[${rec_count}]${C_RESET} ${T_LABEL}Review Security Issues${C_RESET}\n"
        printf "      → ${sec_count} security concerns detected\n"
        printf "      → Check double-extension files and world-writable permissions\n\n"
    fi

    
    local large_count
    large_count=$(awk -v limit=$((100 * 1048576)) '$1>=limit{c++}END{print c+0}' "${TMP_LARGE_FILES}" 2>/dev/null || echo 0)
    if [[ "${large_count}" -gt 0 ]]; then
        (( rec_count++ ))
        printf "  ${T_INFO}[${rec_count}]${C_RESET} ${T_LABEL}Compress Large Files${C_RESET}\n"
        printf "      → ${large_count} files over 100MB could be compressed\n"
        printf "      → Use gzip, bzip2, or xz for significant space savings\n\n"
    fi

    [[ "${rec_count}" -eq 0 ]] && printf "  ${T_GOOD}✔ No cleanup recommendations – directory looks healthy!${C_RESET}\n"

    printf "\n"
    read -rp "  Press ENTER to continue..." _
}


save_history_entry() {
    local entry="${SCAN_ID}|$(timestamp_now)|${SCAN_TARGET}|${SCAN_TOTAL_FILES}|${SCAN_TOTAL_DIRS}|${SCAN_TOTAL_SIZE}|$(wc -l < "${TMP_DUPLICATES_FILE}" 2>/dev/null | tr -d ' ')|${SCAN_HEALTH_SCORE}|${OUTPUT_DIR}"
    echo "${entry}" >> "${LOOKUP_HISTORY_DB}"

    
    local max="${LOOKUP_MAX_HISTORY:-50}"
    local lines
    lines=$(grep -v '^#' "${LOOKUP_HISTORY_DB}" | wc -l | tr -d ' ')
    if (( lines > max )); then
        local tmp
        tmp=$(mktemp)
        grep '^#' "${LOOKUP_HISTORY_DB}" > "${tmp}"
        grep -v '^#' "${LOOKUP_HISTORY_DB}" | tail -"${max}" >> "${tmp}"
        mv "${tmp}" "${LOOKUP_HISTORY_DB}"
    fi
}

show_history() {
    clear_screen
    print_banner
    print_section_header "SCAN HISTORY"

    printf "\n  ${T_LABEL}%-20s  %-10s  %-35s  %8s  %10s  %5s${C_RESET}\n" \
        "SCAN ID" "DATE" "PATH" "FILES" "SIZE" "SCORE"
    print_line

    local count=0
    while IFS='|' read -r id date path files dirs size dups score report_dir; do
        [[ "${id}" =~ ^# ]] && continue
        printf "  ${T_DIM}%-20s${C_RESET}  ${T_VALUE}%-10s${C_RESET}  ${T_INFO}%-35s${C_RESET}  %8s  %10s  " \
            "${id}" "${date:0:10}" "${path:0:35}" "${files}" "$(human_size ${size:-0})"
        local sc="${score:-0}"
        local sc_color
        sc_color=$(score_color "${sc}")
        printf "${sc_color}%5s${C_RESET}\n" "${sc}"
        (( count++ ))
    done < "${LOOKUP_HISTORY_DB}"

    [[ "${count}" -eq 0 ]] && printf "  ${T_DIM}No history yet. Run a scan first.${C_RESET}\n"

    printf "\n"
    read -rp "  Press ENTER to continue..." _
}

compare_scans() {
    clear_screen
    print_banner
    print_section_header "COMPARE SCANS"

    printf "\n  ${T_DIM}Available scans:${C_RESET}\n\n"
    local ids=()
    while IFS='|' read -r id date path files dirs size dups score report_dir; do
        [[ "${id}" =~ ^# ]] && continue
        ids+=("${id}")
        printf "  ${T_VALUE}%-22s${C_RESET}  %s  ${T_DIM}%s${C_RESET}  files:${T_INFO}%s${C_RESET}  score:$(score_color ${score:-0})%s${C_RESET}\n" \
            "${id}" "${date:0:16}" "${path:0:35}" "${files}" "${score}"
    done < "${LOOKUP_HISTORY_DB}"

    if [[ "${#ids[@]}" -lt 2 ]]; then
        printf "\n  ${T_WARN}Need at least 2 scans to compare.${C_RESET}\n\n"
        read -rp "  Press ENTER to continue..." _
        return
    fi

    printf "\n  ${T_LABEL}Enter first Scan ID:${C_RESET}  "
    read -r id1
    printf "  ${T_LABEL}Enter second Scan ID:${C_RESET} "
    read -r id2

    local s1 s2
    s1=$(grep "^${id1}|" "${LOOKUP_HISTORY_DB}" 2>/dev/null | head -1)
    s2=$(grep "^${id2}|" "${LOOKUP_HISTORY_DB}" 2>/dev/null | head -1)

    if [[ -z "${s1}" || -z "${s2}" ]]; then
        printf "\n  ${T_ERROR}One or both scan IDs not found.${C_RESET}\n\n"
        read -rp "  Press ENTER to continue..." _
        return
    fi

    IFS='|' read -r _id1 date1 path1 files1 dirs1 size1 dups1 score1 _ <<< "${s1}"
    IFS='|' read -r _id2 date2 path2 files2 dirs2 size2 dups2 score2 _ <<< "${s2}"

    printf "\n"
    print_line
    printf "  ${T_LABEL}%-20s  ${C_RESET}${T_VALUE}%-25s${C_RESET}  ${T_VALUE}%-25s${C_RESET}  ${T_ACCENT}CHANGE${C_RESET}\n" \
        "METRIC" "SCAN 1 (${id1:0:15})" "SCAN 2 (${id2:0:15})"
    print_line
    _compare_row "Path"     "${path1:0:25}" "${path2:0:25}"
    _compare_row "Date"     "${date1:0:16}" "${date2:0:16}"
    _compare_num "Files"    "${files1:-0}"  "${files2:-0}"
    _compare_num "Dirs"     "${dirs1:-0}"   "${dirs2:-0}"
    _compare_sz  "Size"     "${size1:-0}"   "${size2:-0}"
    _compare_num "Dupes"    "${dups1:-0}"   "${dups2:-0}"
    _compare_num "Score"    "${score1:-0}"  "${score2:-0}"
    print_line

    printf "\n"
    read -rp "  Press ENTER to continue..." _
}

_compare_row() {
    printf "  ${T_LABEL}%-20s${C_RESET}  ${T_VALUE}%-25s${C_RESET}  ${T_VALUE}%-25s${C_RESET}\n" "$1" "$2" "$3"
}

_compare_num() {
    local label="$1" v1="${2:-0}" v2="${3:-0}"
    local diff=$(( v2 - v1 ))
    local color="${T_VALUE}"
    local arrow="  "
    (( diff > 0 )) && { color="${T_WARN}"; arrow="▲ +${diff}"; }
    (( diff < 0 )) && { color="${T_GOOD}"; arrow="▼ ${diff}"; }
    printf "  ${T_LABEL}%-20s${C_RESET}  ${T_VALUE}%-25s${C_RESET}  ${T_VALUE}%-25s${C_RESET}  ${color}%s${C_RESET}\n" \
        "${label}" "${v1}" "${v2}" "${arrow}"
}

_compare_sz() {
    local label="$1" v1="${2:-0}" v2="${3:-0}"
    local diff=$(( v2 - v1 ))
    local color="${T_VALUE}"
    local arrow="  "
    (( diff > 0 )) && { color="${T_WARN}"; arrow="▲ +$(human_size ${diff})"; }
    (( diff < 0 )) && { color="${T_GOOD}"; arrow="▼ $(human_size $(( -diff )))"; }
    printf "  ${T_LABEL}%-20s${C_RESET}  ${T_VALUE}%-25s${C_RESET}  ${T_VALUE}%-25s${C_RESET}  ${color}%s${C_RESET}\n" \
        "${label}" "$(human_size ${v1})" "$(human_size ${v2})" "${arrow}"
}


create_snapshot() {
    local label="${1:-manual}"
    local snap_id
    snap_id="snap_$(generate_id)_${label}"
    local snap_dir="${LOOKUP_SNAPSHOTS_DIR}/${snap_id}"
    mkdir -p "${snap_dir}"

    cp "${TMP_SIZES_LIST}"    "${snap_dir}/sizes.lst"   2>/dev/null || true
    cp "${TMP_FILES_LIST}"    "${snap_dir}/files.list"  2>/dev/null || true
    cp "${TMP_HASHES_FILE}"   "${snap_dir}/hashes.lst"  2>/dev/null || true

    cat > "${snap_dir}/meta.conf" <<EOF
SNAP_ID=${snap_id}
SNAP_DATE=$(timestamp_now)
SNAP_PATH=${SCAN_TARGET}
SNAP_LABEL=${label}
SNAP_FILES=${SCAN_TOTAL_FILES}
SNAP_SIZE=${SCAN_TOTAL_SIZE}
SNAP_SCORE=${SCAN_HEALTH_SCORE}
EOF

    printf "  ${T_GOOD}✔ Snapshot saved:${C_RESET} ${T_VALUE}%s${C_RESET}\n" "${snap_dir}"
    echo "${snap_id}"
}

show_snapshots() {
    clear_screen
    print_banner
    print_section_header "SNAPSHOT SYSTEM"
    printf "\n"

    local count=0
    for meta in "${LOOKUP_SNAPSHOTS_DIR}"/*/meta.conf; do
        [[ -f "${meta}" ]] || continue
        source "${meta}" 2>/dev/null || continue
        printf "  ${T_VALUE}%-35s${C_RESET}  ${T_DIM}%s${C_RESET}  ${T_INFO}%-30s${C_RESET}  files:${T_VALUE}%s${C_RESET}  size:${T_VALUE}%s${C_RESET}\n" \
            "${SNAP_ID}" "${SNAP_DATE:0:16}" "${SNAP_PATH:0:30}" "${SNAP_FILES}" "$(human_size ${SNAP_SIZE:-0})"
        (( count++ ))
    done

    [[ "${count}" -eq 0 ]] && printf "  ${T_DIM}No snapshots yet.${C_RESET}\n"

    printf "\n  ${T_DIM}Snapshots stored in: ${LOOKUP_SNAPSHOTS_DIR}${C_RESET}\n\n"
    read -rp "  Press ENTER to continue..." _
}


generate_all_reports() {
    local scan_date
    scan_date=$(timestamp_now | tr ' ' '_' | tr ':' '-')
    local base_name="lookup_report_${SCAN_ID}"

    REPORT_JSON="${OUTPUT_DIR}/${base_name}.json"
    REPORT_CSV="${OUTPUT_DIR}/${base_name}.csv"
    REPORT_TXT="${OUTPUT_DIR}/${base_name}.txt"
    REPORT_HTML="${OUTPUT_DIR}/${base_name}.html"
    REPORT_PDF="${OUTPUT_DIR}/${base_name}.pdf"

    mkdir -p "${OUTPUT_DIR}"

    printf "\n  ${T_INFO}Generating reports...${C_RESET}\n"

    _generate_json_report
    printf "  ${T_GOOD}✔ JSON${C_RESET} → %s\n" "${REPORT_JSON}"

    _generate_csv_report
    printf "  ${T_GOOD}✔ CSV${C_RESET}  → %s\n" "${REPORT_CSV}"

    _generate_txt_report
    printf "  ${T_GOOD}✔ TXT${C_RESET}  → %s\n" "${REPORT_TXT}"

    _generate_html_report
    printf "  ${T_GOOD}✔ HTML${C_RESET} → %s\n" "${REPORT_HTML}"

    _generate_pdf_report
    if [[ -f "${REPORT_PDF}" ]]; then
        printf "  ${T_GOOD}✔ PDF${C_RESET}  → %s\n" "${REPORT_PDF}"
    else
        printf "  ${T_WARN}⚠ PDF generation skipped (wkhtmltopdf not installed).${C_RESET}\n"
        REPORT_PDF=""
    fi
}

_generate_json_report() {
    local dup_count empty_count empty_dirs sec_count wasted_size
    dup_count=$(wc -l < "${TMP_DUPLICATES_FILE}" 2>/dev/null | tr -d ' ')
    empty_count=$(wc -l < "${TMP_EMPTY_FILES}" 2>/dev/null | tr -d ' ')
    empty_dirs=$(wc -l < "${TMP_EMPTY_DIRS}" 2>/dev/null | tr -d ' ')
    sec_count=$(wc -l < "${TMP_SECURITY_FILE}" 2>/dev/null | tr -d ' ')

    wasted_size=0
    while IFS=' ' read -r hash path; do
        local fsz
        fsz=$(stat -c '%s' "${path}" 2>/dev/null || echo 0)
        wasted_size=$(( wasted_size + fsz ))
    done < "${TMP_DUPLICATES_FILE}" 2>/dev/null || true

    cat > "${REPORT_JSON}" <<EOF
{
  "lookup_report": {
    "version": "${LOOKUP_VERSION}",
    "scan_id": "${SCAN_ID}",
    "scan_date": "$(timestamp_now)",
    "target_path": "${SCAN_TARGET}",
    "summary": {
      "total_files": ${SCAN_TOTAL_FILES},
      "total_dirs": ${SCAN_TOTAL_DIRS},
      "total_size_bytes": ${SCAN_TOTAL_SIZE},
      "health_score": ${SCAN_HEALTH_SCORE},
      "duplicate_files": ${dup_count:-0},
      "wasted_space_bytes": ${wasted_size},
      "empty_files": ${empty_count:-0},
      "empty_dirs": ${empty_dirs:-0},
      "security_issues": ${sec_count:-0}
    },
    "large_files": [
EOF
    local first=true
    while IFS=' ' read -r size path; do
        [[ "${first}" == "true" ]] && first=false || printf ',' >> "${REPORT_JSON}"
        printf '      {"path": "%s", "size": %s}\n' "${path//\"/\\\"}" "${size}" >> "${REPORT_JSON}"
    done < <(head -20 "${TMP_LARGE_FILES}" 2>/dev/null)
    cat >> "${REPORT_JSON}" <<'EOF'
    ],
    "security_issues": [
EOF
    first=true
    while IFS='|' read -r type path detail; do
        [[ "${first}" == "true" ]] && first=false || printf ',' >> "${REPORT_JSON}"
        printf '      {"type": "%s", "path": "%s", "detail": "%s"}\n' "${type}" "${path//\"/\\\"}" "${detail}" >> "${REPORT_JSON}"
    done < "${TMP_SECURITY_FILE}" 2>/dev/null || true
    cat >> "${REPORT_JSON}" <<'EOF'
    ]
  }
}
EOF
}

_generate_csv_report() {
    {
        echo "filepath,size_bytes,size_human,extension,permissions,owner,group,age_days"
        while IFS='|' read -r filepath size mtime atime perms owner group ext; do
            local age_days=$(( ($(epoch_now) - ${mtime:-0}) / 86400 ))
            echo "\"${filepath}\",${size},\"$(human_size ${size})\",\"${ext}\",\"${perms}\",\"${owner}\",\"${group}\",${age_days}"
        done < "${TMP_SIZES_LIST}"
    } > "${REPORT_CSV}"
}

_generate_txt_report() {
    {
        echo "======================================================================"
        echo "  LookUp Storage Intelligence Report"
        echo "  Version: ${LOOKUP_VERSION}"
        echo "  Scan ID: ${SCAN_ID}"
        echo "  Date:    $(timestamp_now)"
        echo "  Target:  ${SCAN_TARGET}"
        echo "======================================================================"
        echo ""
        echo "SUMMARY"
        echo "----------------------------------------------------------------------"
        printf "  Total Files:      %s\n" "${SCAN_TOTAL_FILES}"
        printf "  Total Dirs:       %s\n" "${SCAN_TOTAL_DIRS}"
        printf "  Total Size:       %s\n" "$(human_size ${SCAN_TOTAL_SIZE})"
        printf "  Health Score:     %s/100 (%s)\n" "${SCAN_HEALTH_SCORE}" "$(score_label ${SCAN_HEALTH_SCORE})"
        echo ""
        echo "TOP 20 LARGEST FILES"
        echo "----------------------------------------------------------------------"
        head -20 "${TMP_LARGE_FILES}" 2>/dev/null | while IFS=' ' read -r size path; do
            printf "  %-12s  %s\n" "$(human_size ${size})" "${path}"
        done
        echo ""
        echo "SECURITY ISSUES"
        echo "----------------------------------------------------------------------"
        while IFS='|' read -r type path detail; do
            printf "  [%s] %s  (%s)\n" "${type}" "${path}" "${detail}"
        done < "${TMP_SECURITY_FILE}" 2>/dev/null || echo "  None detected."
        echo ""
        echo "======================================================================"
        echo "  Report generated by LookUp v${LOOKUP_VERSION}"
        echo "======================================================================"
    } > "${REPORT_TXT}"
}

_generate_html_report() {
    local dup_count empty_count sec_count wasted_size
    dup_count=$(wc -l < "${TMP_DUPLICATES_FILE}" 2>/dev/null | tr -d ' ')
    empty_count=$(wc -l < "${TMP_EMPTY_FILES}" 2>/dev/null | tr -d ' ')
    sec_count=$(wc -l < "${TMP_SECURITY_FILE}" 2>/dev/null | tr -d ' ')
    wasted_size=0
    while IFS=' ' read -r hash path; do
        local fsz
        fsz=$(stat -c '%s' "${path}" 2>/dev/null || echo 0)
        wasted_size=$(( wasted_size + fsz ))
    done < "${TMP_DUPLICATES_FILE}" 2>/dev/null || true

    local score_color_hex="28a745"
    (( SCAN_HEALTH_SCORE < 70 )) && score_color_hex="ffc107"
    (( SCAN_HEALTH_SCORE < 50 )) && score_color_hex="dc3545"

  
    local large_rows=""
    while IFS=' ' read -r size path; do
        large_rows+="<tr><td>$(human_size ${size})</td><td class='path'>${path}</td></tr>"
    done < <(head -20 "${TMP_LARGE_FILES}" 2>/dev/null)

    
    local sec_rows=""
    while IFS='|' read -r type path detail; do
        local badge_class="warning"
        [[ "${type}" == "DOUBLE_EXT" ]] && badge_class="danger"
        sec_rows+="<tr><td><span class='badge ${badge_class}'>${type}</span></td><td class='path'>${path}</td><td>${detail}</td></tr>"
    done < "${TMP_SECURITY_FILE}" 2>/dev/null || true

  
    local ext_rows=""
    while IFS=' ' read -r count size ext; do
        local pct=0
        [[ "${SCAN_TOTAL_SIZE}" -gt 0 ]] && pct=$(( size * 100 / SCAN_TOTAL_SIZE ))
        ext_rows+="<tr><td>.${ext}</td><td>${count}</td><td>$(human_size ${size})</td><td><div class='bar-wrap'><div class='bar' style='width:${pct}%'></div></div></td></tr>"
    done < <(head -20 "${TMP_EXT_STATS}" 2>/dev/null)

    cat > "${REPORT_HTML}" <<HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>LookUp Report – ${SCAN_TARGET}</title>
<style>
  :root {
    --bg: #0d1117; --surface: #161b22; --border: #30363d;
    --text: #e6edf3; --muted: #8b949e; --accent: #58a6ff;
    --green: #3fb950; --yellow: #d29922; --red: #f85149;
    --purple: #bc8cff;
  }
  body.light {
    --bg: #f6f8fa; --surface: #ffffff; --border: #d0d7de;
    --text: #1f2328; --muted: #636c76; --accent: #0969da;
    --green: #1a7f37; --yellow: #9a6700; --red: #cf222e;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: var(--bg); color: var(--text); font-family: 'Segoe UI', system-ui, sans-serif; font-size: 14px; }
  header { background: var(--surface); border-bottom: 1px solid var(--border); padding: 20px 32px; display: flex; align-items: center; justify-content: space-between; }
  header h1 { font-size: 22px; color: var(--accent); letter-spacing: 2px; }
  header span { color: var(--muted); font-size: 12px; }
  .toolbar { background: var(--surface); border-bottom: 1px solid var(--border); padding: 8px 32px; display: flex; gap: 12px; align-items: center; }
  .toolbar input { background: var(--bg); border: 1px solid var(--border); color: var(--text); padding: 6px 12px; border-radius: 6px; font-size: 13px; width: 260px; }
  .toolbar button { background: var(--accent); color: #fff; border: none; padding: 6px 14px; border-radius: 6px; cursor: pointer; font-size: 13px; }
  .toolbar button:hover { opacity: 0.85; }
  main { max-width: 1400px; margin: 0 auto; padding: 28px 32px; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 28px; }
  .card { background: var(--surface); border: 1px solid var(--border); border-radius: 10px; padding: 20px; }
  .card .label { color: var(--muted); font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 6px; }
  .card .value { font-size: 26px; font-weight: 700; color: var(--accent); }
  .card .sub { font-size: 12px; color: var(--muted); margin-top: 4px; }
  .score-card .value { color: #${score_color_hex}; font-size: 40px; }
  section { background: var(--surface); border: 1px solid var(--border); border-radius: 10px; padding: 24px; margin-bottom: 24px; }
  section h2 { font-size: 15px; font-weight: 600; color: var(--accent); margin-bottom: 16px; border-bottom: 1px solid var(--border); padding-bottom: 10px; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; }
  th { text-align: left; color: var(--muted); font-size: 11px; text-transform: uppercase; letter-spacing: 1px; padding: 8px 12px; border-bottom: 1px solid var(--border); }
  td { padding: 8px 12px; border-bottom: 1px solid var(--border); vertical-align: middle; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: rgba(88,166,255,0.05); }
  .path { font-family: monospace; font-size: 12px; color: var(--muted); word-break: break-all; }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 600; }
  .badge.danger  { background: rgba(248,81,73,0.15); color: var(--red); }
  .badge.warning { background: rgba(210,153,34,0.15); color: var(--yellow); }
  .bar-wrap { background: var(--border); border-radius: 4px; height: 8px; width: 120px; }
  .bar { background: var(--accent); height: 8px; border-radius: 4px; }
  .health-bar-wrap { background: var(--border); border-radius: 8px; height: 14px; width: 200px; display: inline-block; vertical-align: middle; }
  .health-bar { background: #${score_color_hex}; height: 14px; border-radius: 8px; width: ${SCAN_HEALTH_SCORE}%; }
  footer { text-align: center; color: var(--muted); font-size: 12px; padding: 24px; }
</style>
</head>
<body>
<header>
  <div>
    <h1>⬡ LOOKUP</h1>
    <div style="color:var(--muted);font-size:12px;margin-top:4px;">${LOOKUP_TAGLINE}</div>
  </div>
  <div style="text-align:right;">
    <div style="font-size:13px;color:var(--text);">${SCAN_TARGET}</div>
    <span>Scan ID: ${SCAN_ID} &nbsp;|&nbsp; $(timestamp_now)</span>
  </div>
</header>

<div class="toolbar">
  <input type="text" id="searchBox" oninput="filterTable()" placeholder="🔍 Search paths, extensions...">
  <button onclick="document.body.classList.toggle('light')">Toggle Light/Dark</button>
  <button onclick="window.print()">Print / Export PDF</button>
</div>

<main>
  <!-- Summary Cards -->
  <div class="grid">
    <div class="card score-card">
      <div class="label">Health Score</div>
      <div class="value">${SCAN_HEALTH_SCORE}</div>
      <div class="sub">$(score_label ${SCAN_HEALTH_SCORE}) &nbsp; <span class="health-bar-wrap"><span class="health-bar"></span></span></div>
    </div>
    <div class="card">
      <div class="label">Total Files</div>
      <div class="value">${SCAN_TOTAL_FILES}</div>
      <div class="sub">in ${SCAN_TOTAL_DIRS} directories</div>
    </div>
    <div class="card">
      <div class="label">Total Size</div>
      <div class="value">$(human_size ${SCAN_TOTAL_SIZE})</div>
      <div class="sub">${SCAN_TOTAL_SIZE} bytes</div>
    </div>
    <div class="card">
      <div class="label">Duplicate Files</div>
      <div class="value" style="color:var(--yellow)">${dup_count:-0}</div>
      <div class="sub">$(human_size ${wasted_size}) wasted</div>
    </div>
    <div class="card">
      <div class="label">Security Issues</div>
      <div class="value" style="color:var(--red)">${sec_count:-0}</div>
      <div class="sub">review recommended</div>
    </div>
    <div class="card">
      <div class="label">Empty Files</div>
      <div class="value" style="color:var(--muted)">${empty_count:-0}</div>
      <div class="sub">zero-byte files</div>
    </div>
  </div>

  <!-- Large Files -->
  <section>
    <h2>📦 Top 20 Largest Files</h2>
    <table id="largeTable">
      <thead><tr><th>Size</th><th>Path</th></tr></thead>
      <tbody>${large_rows}</tbody>
    </table>
  </section>

  <!-- File Type Breakdown -->
  <section>
    <h2>📂 Storage by File Type</h2>
    <table>
      <thead><tr><th>Extension</th><th>Count</th><th>Size</th><th style="width:140px">% of Total</th></tr></thead>
      <tbody>${ext_rows}</tbody>
    </table>
  </section>

  <!-- Security -->
  <section>
    <h2>🔐 Security Analysis</h2>
    <table id="secTable">
      <thead><tr><th>Type</th><th>Path</th><th>Detail</th></tr></thead>
      <tbody>
        $(if [[ -z "${sec_rows}" ]]; then echo "<tr><td colspan='3' style='color:var(--green)'>✔ No security issues detected</td></tr>"; else echo "${sec_rows}"; fi)
      </tbody>
    </table>
  </section>

</main>

<footer>
  Generated by LookUp v${LOOKUP_VERSION} &nbsp;|&nbsp; ${LOOKUP_TAGLINE}
</footer>

<script>
function filterTable() {
  const q = document.getElementById('searchBox').value.toLowerCase();
  document.querySelectorAll('table tbody tr').forEach(row => {
    row.style.display = row.textContent.toLowerCase().includes(q) ? '' : 'none';
  });
}
</script>
</body>
</html>
HTMLEOF
}

_generate_pdf_report() {
    if [[ "${HAS_WKHTMLTOPDF}" == "true" && -f "${REPORT_HTML}" ]]; then
        wkhtmltopdf --quiet --page-size A4 --margin-top 15mm --margin-bottom 15mm \
            --margin-left 15mm --margin-right 15mm \
            "${REPORT_HTML}" "${REPORT_PDF}" 2>/dev/null || true
    elif [[ "${HAS_PANDOC}" == "true" && -f "${REPORT_TXT}" ]]; then
      
        pandoc "${REPORT_TXT}" -o "${REPORT_PDF}" 2>/dev/null || true
    else
        
        if [[ "${HAS_ENSCRIPT}" == "true" ]] && command -v ps2pdf &>/dev/null; then
            local tmp_ps="${LOOKUP_TMP_DIR}/report.ps"
            enscript -q -o "${tmp_ps}" "${REPORT_TXT}" 2>/dev/null && \
                ps2pdf "${tmp_ps}" "${REPORT_PDF}" 2>/dev/null || true
        fi
    fi
}


add_favorite() {
    local path="${1:-${SCAN_TARGET}}"
    [[ -z "${path}" ]] && return
    grep -qxF "${path}" "${LOOKUP_FAVORITES_FILE}" 2>/dev/null || echo "${path}" >> "${LOOKUP_FAVORITES_FILE}"
    printf "  ${T_GOOD}✔ Added to favorites:${C_RESET} %s\n" "${path}"
}

show_favorites() {
    clear_screen
    print_banner
    print_section_header "SAVED FAVORITES"
    printf "\n"

    local count=0
    if [[ -f "${LOOKUP_FAVORITES_FILE}" ]]; then
        while IFS= read -r line; do
            [[ -z "${line}" ]] && continue
            local exists="${T_ERROR}✗"
            [[ -d "${line}" ]] && exists="${T_GOOD}✔"
            printf "  %b  ${T_VALUE}%s${C_RESET}\n" "${exists}" "${line}"
            (( count++ ))
        done < "${LOOKUP_FAVORITES_FILE}"
    fi

    [[ "${count}" -eq 0 ]] && printf "  ${T_DIM}No favorites saved yet.${C_RESET}\n"
    printf "\n"
    read -rp "  Press ENTER to continue..." _
}

add_bookmark() {
    local path="${1:-${SCAN_TARGET}}"
    local note="${2:-}"
    [[ -z "${path}" ]] && return
    echo "${path}|${note}|$(timestamp_now)" >> "${LOOKUP_BOOKMARKS_FILE}"
    printf "  ${T_GOOD}✔ Bookmarked:${C_RESET} %s\n" "${path}"
}


show_settings() {
    while true; do
        clear_screen
        print_banner
        print_section_header "SETTINGS"

        source "${LOOKUP_CONFIG_FILE}" 2>/dev/null || true

        printf "\n"
        printf "  ${T_LABEL}%s${C_RESET}  ${T_DIM}Current value:${C_RESET} ${T_VALUE}%s${C_RESET}\n" \
            "1. Theme (dark/light)" "${LOOKUP_THEME:-dark}"
        printf "  ${T_LABEL}%s${C_RESET}  ${T_DIM}Current value:${C_RESET} ${T_VALUE}%s${C_RESET}\n" \
            "2. Default scan dir  " "${LOOKUP_DEFAULT_SCAN_DIR:-${HOME}}"
        printf "  ${T_LABEL}%s${C_RESET}  ${T_DIM}Current value:${C_RESET} ${T_VALUE}%s${C_RESET}\n" \
            "3. Reports directory " "${LOOKUP_REPORT_DIR:-${LOOKUP_REPORTS_DIR}}"
        printf "  ${T_LABEL}%s${C_RESET}  ${T_DIM}Current value:${C_RESET} ${T_VALUE}%s${C_RESET}\n" \
            "4. SHA256 hashing    " "${LOOKUP_HASH_ENABLED:-true}"
        printf "  ${T_LABEL}%s${C_RESET}  ${T_DIM}Current value:${C_RESET} ${T_VALUE}%s${C_RESET}\n" \
            "5. Show hidden files " "${LOOKUP_SHOW_HIDDEN:-false}"
        printf "  ${T_LABEL}%s${C_RESET}  ${T_DIM}Current value:${C_RESET} ${T_VALUE}%s${C_RESET}\n" \
            "6. Max history count " "${LOOKUP_MAX_HISTORY:-50}"
        printf "  ${T_LABEL}%s${C_RESET}  ${T_DIM}Current value:${C_RESET} ${T_VALUE}%s MB${C_RESET}\n" \
            "7. Large file limit  " "${LOOKUP_LARGE_FILE_MB:-100}"
        printf "  ${T_LABEL}%s${C_RESET}\n" "8. Run first-run wizard"
        printf "  ${T_LABEL}%s${C_RESET}\n" "0. Back"
        printf "\n"

        read -rp "  ${T_ACCENT}Choose option:${C_RESET} " opt
        case "${opt}" in
            1) read -rp "  Theme (dark/light): " val
               sed -i "s/^LOOKUP_THEME=.*/LOOKUP_THEME=${val:-dark}/" "${LOOKUP_CONFIG_FILE}"
               CURRENT_THEME="${val:-dark}"; load_theme ;;
            2) read -rp "  Default scan dir: " val
               sed -i "s|^LOOKUP_DEFAULT_SCAN_DIR=.*|LOOKUP_DEFAULT_SCAN_DIR=${val:-${HOME}}|" "${LOOKUP_CONFIG_FILE}" ;;
            3) read -rp "  Reports directory: " val
               mkdir -p "${val}" 2>/dev/null
               sed -i "s|^LOOKUP_REPORT_DIR=.*|LOOKUP_REPORT_DIR=${val}|" "${LOOKUP_CONFIG_FILE}"
               OUTPUT_DIR="${val}" ;;
            4) read -rp "  SHA256 hashing (true/false): " val
               sed -i "s/^LOOKUP_HASH_ENABLED=.*/LOOKUP_HASH_ENABLED=${val:-true}/" "${LOOKUP_CONFIG_FILE}" ;;
            5) read -rp "  Show hidden files (true/false): " val
               sed -i "s/^LOOKUP_SHOW_HIDDEN=.*/LOOKUP_SHOW_HIDDEN=${val:-false}/" "${LOOKUP_CONFIG_FILE}" ;;
            6) read -rp "  Max history count: " val
               sed -i "s/^LOOKUP_MAX_HISTORY=.*/LOOKUP_MAX_HISTORY=${val:-50}/" "${LOOKUP_CONFIG_FILE}" ;;
            7) read -rp "  Large file threshold (MB): " val
               sed -i "s/^LOOKUP_LARGE_FILE_MB=.*/LOOKUP_LARGE_FILE_MB=${val:-100}/" "${LOOKUP_CONFIG_FILE}" ;;
            8) first_run_wizard; load_config; load_theme ;;
            0|q|Q) break ;;
        esac
        load_config
    done
}


interactive_search() {
    clear_screen
    print_banner
    print_section_header "FILE SEARCH"
    printf "\n"

    printf "  Search by: ${T_LABEL}1${C_RESET}) Name  ${T_LABEL}2${C_RESET}) Extension  ${T_LABEL}3${C_RESET}) Size  ${T_LABEL}4${C_RESET}) Age  ${T_LABEL}5${C_RESET}) Permissions\n\n"
    read -rp "  ${T_ACCENT}Choose:${C_RESET} " search_type

    case "${search_type}" in
        1)
            read -rp "  ${T_LABEL}Filename pattern (glob, e.g. *.log):${C_RESET} " pattern
            printf "\n  ${T_HEADER}Results:${C_RESET}\n\n"
            grep -i "${pattern}" "${TMP_FILES_LIST}" 2>/dev/null | head -100 | while read -r f; do
                printf "  ${T_VALUE}%s${C_RESET}\n" "${f}"
            done
            ;;
        2)
            read -rp "  ${T_LABEL}Extension (e.g. pdf):${C_RESET} " ext
            ext="${ext,,}"
            printf "\n  ${T_HEADER}Results:${C_RESET}\n\n"
            awk -F'|' -v e="${ext}" 'tolower($8)==e{print $1 "|" $2}' "${TMP_SIZES_LIST}" 2>/dev/null | head -100 | \
                while IFS='|' read -r path size; do
                    printf "  ${T_VALUE}%12s${C_RESET}  ${T_DIM}%s${C_RESET}\n" "$(human_size ${size})" "${path}"
                done
            ;;
        3)
            read -rp "  ${T_LABEL}Min size (MB):${C_RESET} " min_mb
            local min_bytes=$(( ${min_mb:-0} * 1048576 ))
            printf "\n  ${T_HEADER}Files larger than %s MB:${C_RESET}\n\n" "${min_mb}"
            awk -F'|' -v m="${min_bytes}" '$2>=m{print $2 " " $1}' "${TMP_SIZES_LIST}" 2>/dev/null | \
                sort -rn | head -50 | while IFS=' ' read -r size path; do
                    printf "  ${T_VALUE}%12s${C_RESET}  ${T_DIM}%s${C_RESET}\n" "$(human_size ${size})" "${path}"
                done
            ;;
        4)
            read -rp "  ${T_LABEL}Older than (days):${C_RESET} " days
            local cutoff=$(( $(epoch_now) - ${days:-365} * 86400 ))
            printf "\n  ${T_HEADER}Files not modified in %s+ days:${C_RESET}\n\n" "${days}"
            awk -F'|' -v c="${cutoff}" '$3<=c{print $1}' "${TMP_SIZES_LIST}" 2>/dev/null | head -100 | \
                while read -r f; do printf "  ${T_DIM}%s${C_RESET}\n" "${f}"; done
            ;;
        5)
            read -rp "  ${T_LABEL}Permission octal (e.g. 777):${C_RESET} " perm
            printf "\n  ${T_HEADER}Files with permission %s:${C_RESET}\n\n" "${perm}"
            awk -F'|' -v p="${perm}" '$5==p{print $1}' "${TMP_SIZES_LIST}" 2>/dev/null | head -100 | \
                while read -r f; do printf "  ${T_WARN}%s${C_RESET}\n" "${f}"; done
            ;;
        *) printf "  ${T_ERROR}Invalid choice.${C_RESET}\n" ;;
    esac

    printf "\n"
    read -rp "  Press ENTER to continue..." _
}


show_help() {
    clear_screen
    print_banner
    print_section_header "HELP & DOCUMENTATION"

    cat <<HELPEOF

  ${T_LABEL}USAGE${C_RESET}
    lookup.sh [OPTIONS] [DIRECTORY]

  ${T_LABEL}OPTIONS${C_RESET}
    ${T_VALUE}-s, --scan DIR${C_RESET}        Scan a directory directly
    ${T_VALUE}-q, --quiet${C_RESET}           Suppress progress output
    ${T_VALUE}-v, --verbose${C_RESET}         Verbose logging
    ${T_VALUE}--no-hash${C_RESET}             Skip SHA256 duplicate detection
    ${T_VALUE}--no-security${C_RESET}         Skip security analysis
    ${T_VALUE}--report-dir DIR${C_RESET}      Output reports to DIR
    ${T_VALUE}--theme THEME${C_RESET}         Use 'dark' or 'light' theme
    ${T_VALUE}--history${C_RESET}             Show scan history and exit
    ${T_VALUE}--no-interactive${C_RESET}      Run scan and exit (no menu)
    ${T_VALUE}--snapshot${C_RESET}            Create snapshot after scan
    ${T_VALUE}--wizard${C_RESET}              Run first-time setup wizard
    ${T_VALUE}--version${C_RESET}             Show version
    ${T_VALUE}-h, --help${C_RESET}            Show this help

  ${T_LABEL}INTERACTIVE MENU KEYS${C_RESET}
    ${T_VALUE}1-15${C_RESET}      Navigate menu sections
    ${T_VALUE}ENTER${C_RESET}     Confirm / continue
    ${T_VALUE}q / 0${C_RESET}     Back / quit

  ${T_LABEL}DATA LOCATIONS${C_RESET}
    Config:    ${T_VALUE}${LOOKUP_CONFIG_FILE}${C_RESET}
    History:   ${T_VALUE}${LOOKUP_HISTORY_DB}${C_RESET}
    Snapshots: ${T_VALUE}${LOOKUP_SNAPSHOTS_DIR}${C_RESET}
    Reports:   ${T_VALUE}${OUTPUT_DIR}${C_RESET}

  ${T_LABEL}REPORT FORMATS${C_RESET}
    PDF, HTML, JSON, CSV, TXT – generated after every scan.
    HTML report includes dark/light toggle and full-text search.

  ${T_LABEL}EXAMPLES${C_RESET}
    ${T_DIM}# Scan home directory interactively${C_RESET}
    ./lookup.sh

    ${T_DIM}# Scan /var/log non-interactively, output to /tmp/reports${C_RESET}
    ./lookup.sh --scan /var/log --no-interactive --report-dir /tmp/reports

    ${T_DIM}# Scan without hashing (faster, no duplicate detection)${C_RESET}
    ./lookup.sh --scan /data --no-hash

    ${T_DIM}# View scan history${C_RESET}
    ./lookup.sh --history

HELPEOF

    print_dline
    read -rp "  Press ENTER to continue..." _
}


show_main_menu() {
    local scanned=false

    while true; do
        clear_screen
        print_banner

        local scan_status
        if [[ "${scanned}" == "true" ]]; then
            scan_status="${T_GOOD}✔ Scan loaded: ${SCAN_TARGET} (${SCAN_TOTAL_FILES} files, score: ${SCAN_HEALTH_SCORE}/100)${C_RESET}"
        else
            scan_status="${T_DIM}No scan loaded — choose option 2 to scan a directory${C_RESET}"
        fi
        printf "  %b\n\n" "${scan_status}"

        printf "  ${T_HEADER}┌─ MAIN MENU ──────────────────────────────────────────┐${C_RESET}\n"
        printf "  ${T_HEADER}│${C_RESET}  ${T_LABEL} 1.${C_RESET} Dashboard              ${T_LABEL}  9.${C_RESET} Security Analysis    ${T_HEADER}│${C_RESET}\n"
        printf "  ${T_HEADER}│${C_RESET}  ${T_LABEL} 2.${C_RESET} Scan Directory         ${T_LABEL} 10.${C_RESET} Storage Breakdown    ${T_HEADER}│${C_RESET}\n"
        printf "  ${T_HEADER}│${C_RESET}  ${T_LABEL} 3.${C_RESET} Scan History           ${T_LABEL} 11.${C_RESET} Cleanup Suggestions  ${T_HEADER}│${C_RESET}\n"
        printf "  ${T_HEADER}│${C_RESET}  ${T_LABEL} 4.${C_RESET} Compare Scans          ${T_LABEL} 12.${C_RESET} Export / Reports     ${T_HEADER}│${C_RESET}\n"
        printf "  ${T_HEADER}│${C_RESET}  ${T_LABEL} 5.${C_RESET} Duplicate Files        ${T_LABEL} 13.${C_RESET} Settings             ${T_HEADER}│${C_RESET}\n"
        printf "  ${T_HEADER}│${C_RESET}  ${T_LABEL} 6.${C_RESET} Largest Files          ${T_LABEL} 14.${C_RESET} Help                 ${T_HEADER}│${C_RESET}\n"
        printf "  ${T_HEADER}│${C_RESET}  ${T_LABEL} 7.${C_RESET} Old / Forgotten Files  ${T_LABEL} 15.${C_RESET} Favorites            ${T_HEADER}│${C_RESET}\n"
        printf "  ${T_HEADER}│${C_RESET}  ${T_LABEL} 8.${C_RESET} Search Files           ${T_LABEL}  S.${C_RESET} Create Snapshot      ${T_HEADER}│${C_RESET}\n"
        printf "  ${T_HEADER}│${C_RESET}  ${T_LABEL} V.${C_RESET} View Snapshots         ${T_LABEL}  0.${C_RESET} Exit                 ${T_HEADER}│${C_RESET}\n"
        printf "  ${T_HEADER}└──────────────────────────────────────────────────────┘${C_RESET}\n\n"

        read -rp "  ${T_ACCENT}Select option:${C_RESET} " choice

        case "${choice}" in
            1)
                if [[ "${scanned}" == "true" ]]; then
                    show_dashboard
                else
                    printf "\n  ${T_WARN}Run a scan first (option 2).${C_RESET}\n"
                    sleep 1
                fi
                ;;
            2)
                local default_dir="${LOOKUP_DEFAULT_SCAN_DIR:-${HOME}}"
                printf "\n  ${T_LABEL}Enter directory to scan${C_RESET} [${default_dir}]: "
                read -r scan_path
                scan_path="${scan_path:-${default_dir}}"
                if [[ -d "${scan_path}" ]]; then
                    run_scan "${scan_path}"
                    if [[ "${LOOKUP_AUTO_REPORT:-true}" == "true" ]]; then
                        generate_all_reports
                    fi
                    save_history_entry
                    scanned=true
                    show_dashboard
                    read -rp "  Press ENTER to return to menu..." _
                else
                    printf "\n  ${T_ERROR}Directory not found: %s${C_RESET}\n" "${scan_path}"
                    sleep 1
                fi
                ;;
            3)  show_history ;;
            4)  compare_scans ;;
            5)
                [[ "${scanned}" == "true" ]] && show_duplicates || { printf "\n  ${T_WARN}Run a scan first.${C_RESET}\n"; sleep 1; }
                ;;
            6)
                [[ "${scanned}" == "true" ]] && show_large_files || { printf "\n  ${T_WARN}Run a scan first.${C_RESET}\n"; sleep 1; }
                ;;
            7)
                [[ "${scanned}" == "true" ]] && show_old_files || { printf "\n  ${T_WARN}Run a scan first.${C_RESET}\n"; sleep 1; }
                ;;
            8)
                [[ "${scanned}" == "true" ]] && interactive_search || { printf "\n  ${T_WARN}Run a scan first.${C_RESET}\n"; sleep 1; }
                ;;
            9)
                [[ "${scanned}" == "true" ]] && show_security || { printf "\n  ${T_WARN}Run a scan first.${C_RESET}\n"; sleep 1; }
                ;;
            10)
                [[ "${scanned}" == "true" ]] && show_storage_breakdown || { printf "\n  ${T_WARN}Run a scan first.${C_RESET}\n"; sleep 1; }
                ;;
            11)
                [[ "${scanned}" == "true" ]] && show_cleanup_suggestions || { printf "\n  ${T_WARN}Run a scan first.${C_RESET}\n"; sleep 1; }
                ;;
            12)
                if [[ "${scanned}" == "true" ]]; then
                    generate_all_reports
                    printf "\n"
                    read -rp "  Reports generated. Press ENTER to continue..." _
                else
                    printf "\n  ${T_WARN}Run a scan first.${C_RESET}\n"; sleep 1
                fi
                ;;
            13) show_settings ;;
            14) show_help ;;
            15) show_favorites ;;
            s|S)
                if [[ "${scanned}" == "true" ]]; then
                    read -rp "  Snapshot label (e.g. before_cleanup): " snap_label
                    create_snapshot "${snap_label:-manual}"
                    read -rp "  Press ENTER to continue..." _
                else
                    printf "\n  ${T_WARN}Run a scan first.${C_RESET}\n"; sleep 1
                fi
                ;;
            v|V) show_snapshots ;;
            0|q|Q|exit|quit)
                printf "\n  ${T_DIM}Goodbye.${C_RESET}\n\n"
                break
                ;;
            *)
                printf "\n  ${T_WARN}Invalid option.${C_RESET}\n"; sleep 0.5 ;;
        esac
    done
}


parse_args() {
    local scan_dir_arg=""
    local no_interactive=false
    local show_history_only=false
    local do_wizard=false
    local do_snapshot=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--scan)
                scan_dir_arg="${2:-}"
                shift 2
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --no-hash)
                LOOKUP_HASH_ENABLED=false
                shift
                ;;
            --no-security)
                LOOKUP_SECURITY_ENABLED=false
                shift
                ;;
            --report-dir)
                OUTPUT_DIR="${2:-${LOOKUP_REPORTS_DIR}}"
                shift 2
                ;;
            --theme)
                CURRENT_THEME="${2:-dark}"
                shift 2
                ;;
            --history)
                show_history_only=true
                shift
                ;;
            --no-interactive)
                no_interactive=true
                shift
                ;;
            --snapshot)
                do_snapshot=true
                shift
                ;;
            --wizard)
                do_wizard=true
                shift
                ;;
            --version)
                echo "${LOOKUP_NAME} v${LOOKUP_VERSION}"
                exit 0
                ;;
            -h|--help)
                init_all
                show_help
                cleanup_tmp
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
            *)
                
                scan_dir_arg="$1"
                shift
                ;;
        esac
    done

  
    if [[ ! -f "${LOOKUP_CONFIG_FILE}" ]]; then
        init_all
        first_run_wizard
        load_config
        load_theme
    else
        init_all
    fi

    if [[ "${do_wizard}" == "true" ]]; then
        first_run_wizard
        load_config
        load_theme
    fi

    if [[ "${show_history_only}" == "true" ]]; then
        show_history
        cleanup_tmp
        exit 0
    fi

    if [[ -n "${scan_dir_arg}" ]]; then
      
        run_scan "${scan_dir_arg}"
        generate_all_reports
        save_history_entry
        [[ "${do_snapshot}" == "true" ]] && create_snapshot "auto"
        show_dashboard
        if [[ "${no_interactive}" == "false" ]]; then
            printf "\n"
            read -rp "  Press ENTER to open interactive menu..." _
            show_main_menu
        fi
    else
      
        show_main_menu
    fi
}

main() {
  
    if [[ $# -eq 0 ]]; then
        if [[ ! -f "${LOOKUP_CONFIG_FILE}" ]]; then
            init_all
            first_run_wizard
            load_config
            load_theme
        else
            init_all
        fi
        show_main_menu
    else
        parse_args "$@"
    fi

    show_cursor
    cleanup_tmp
}

main "$@"
