#!/usr/bin/env bash
# =============================================================================
# task_manager.sh — Mini Task Management System
# =============================================================================
# Data format (pipe-delimited, one task per line):
#   ID|Title|Status|Priority|DueDate
# =============================================================================

# ── Configuration ─────────────────────────────────────────────────────────────
TASKS_FILE="tasks.txt"
EXPORT_FILE="tasks_export.csv"
DELIMITER="|"

# ── ANSI Colour Palette ────────────────────────────────────────────────────────
RED='\033[0;31m';    BRED='\033[1;31m'
GREEN='\033[0;32m';  BGREEN='\033[1;32m'
YELLOW='\033[0;33m'; BYELLOW='\033[1;33m'
BLUE='\033[0;34m';   BBLUE='\033[1;34m'
CYAN='\033[0;36m';   BCYAN='\033[1;36m'
MAGENTA='\033[0;35m';BMAGENTA='\033[1;35m'
WHITE='\033[1;37m';  DIM='\033[2m'
RESET='\033[0m'

# ── Helper: print coloured messages ───────────────────────────────────────────
info()    { echo -e "${BCYAN}ℹ  $*${RESET}"; }
success() { echo -e "${BGREEN}✔  $*${RESET}"; }
warn()    { echo -e "${BYELLOW}⚠  $*${RESET}"; }
error()   { echo -e "${BRED}✖  $*${RESET}"; }
header()  { echo -e "\n${BBLUE}══════════════════════════════════════════${RESET}"; \
            echo -e "${WHITE}   $*${RESET}"; \
            echo -e "${BBLUE}══════════════════════════════════════════${RESET}"; }

pause()   { echo; read -rp "$(echo -e "${DIM}  Press [Enter] to continue...${RESET}")"; }

# ── Initialise data file ───────────────────────────────────────────────────────
init_file() {
    if [[ ! -f "$TASKS_FILE" ]]; then
        touch "$TASKS_FILE"
        info "Created new task file: $TASKS_FILE"
    fi
}

# ── Generate next unique ID ────────────────────────────────────────────────────
next_id() {
    if [[ ! -s "$TASKS_FILE" ]]; then
        echo 1
        return
    fi
    local max_id
    max_id=$(awk -F"$DELIMITER" 'NF>=1 && $1~/^[0-9]+$/ {print $1+0}' "$TASKS_FILE" \
             | sort -n | tail -1)
    echo $(( max_id + 1 ))
}

# ── Colour-code a status string ────────────────────────────────────────────────
colour_status() {
    case "$1" in
        pending)     echo -e "${YELLOW}pending${RESET}"     ;;
        in-progress) echo -e "${BLUE}in-progress${RESET}"  ;;
        done)        echo -e "${GREEN}done${RESET}"         ;;
        *)           echo "$1" ;;
    esac
}

# ── Colour-code a priority string ─────────────────────────────────────────────
colour_priority() {
    case "$1" in
        high)   echo -e "${BRED}high${RESET}"       ;;
        medium) echo -e "${BYELLOW}medium${RESET}"  ;;
        low)    echo -e "${GREEN}low${RESET}"        ;;
        *)      echo "$1" ;;
    esac
}

# ── Validate date format YYYY-MM-DD ───────────────────────────────────────────
validate_date() {
    local d="$1"
    if [[ ! "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 1
    fi
    # Check the date is calendar-valid using 'date'
    date -d "$d" "+%Y-%m-%d" &>/dev/null || \
    date -j -f "%Y-%m-%d" "$d" "+%Y-%m-%d" &>/dev/null   # macOS fallback
}

# ── Check whether a task ID exists ────────────────────────────────────────────
id_exists() {
    grep -q "^$1${DELIMITER}" "$TASKS_FILE" 2>/dev/null
}

# ── Print a pretty table row ──────────────────────────────────────────────────
# Usage: print_task_row <id> <title> <status> <priority> <duedate>
print_task_row() {
    local id="$1" title="$2" status="$3" priority="$4" due="$5"
    printf "  ${WHITE}%-5s${RESET}  %-28s  %-17s  %-15s  %s\n" \
        "$id" \
        "$title" \
        "$(colour_status "$status")" \
        "$(colour_priority "$priority")" \
        "$due"
}

print_table_header() {
    echo -e "\n  ${BBLUE}$(printf '%-5s  %-28s  %-17s  %-15s  %s' \
        'ID' 'TITLE' 'STATUS' 'PRIORITY' 'DUE DATE')${RESET}"
    echo -e "  ${DIM}$(printf '%0.s─' {1..78})${RESET}"
}

# ═════════════════════════════════════════════════════════════════════════════
# 1. ADD TASK
# ═════════════════════════════════════════════════════════════════════════════
add_task() {
    header "Add New Task"

    # Title
    while true; do
        read -rp "  Title: " title
        title="${title//[$DELIMITER]/}"  # strip delimiter chars from input
        if [[ -z "$title" ]]; then
            warn "Title cannot be empty."
        else
            break
        fi
    done

    # Priority
    while true; do
        read -rp "  Priority (high/medium/low): " priority
        priority="${priority,,}"   # to lowercase
        if [[ "$priority" =~ ^(high|medium|low)$ ]]; then
            break
        else
            warn "Priority must be: high, medium, or low."
        fi
    done

    # Due date
    while true; do
        read -rp "  Due Date (YYYY-MM-DD): " due_date
        if validate_date "$due_date"; then
            break
        else
            warn "Invalid date. Please use the format YYYY-MM-DD (e.g. 2025-12-31)."
        fi
    done

    local id
    id=$(next_id)
    echo "${id}${DELIMITER}${title}${DELIMITER}pending${DELIMITER}${priority}${DELIMITER}${due_date}" \
        >> "$TASKS_FILE"

    success "Task #${id} \"${title}\" added successfully."
    pause
}

# ═════════════════════════════════════════════════════════════════════════════
# 2. LIST TASKS
# ═════════════════════════════════════════════════════════════════════════════
list_tasks() {
    header "List Tasks"

    if [[ ! -s "$TASKS_FILE" ]]; then
        warn "No tasks found."
        pause; return
    fi

    echo -e "  Filter by:  ${WHITE}1${RESET} Status   ${WHITE}2${RESET} Priority   ${WHITE}3${RESET} All"
    read -rp "  Choice [3]: " filter_choice
    filter_choice="${filter_choice:-3}"

    local filter_field="" filter_value=""

    case "$filter_choice" in
        1)
            read -rp "  Status (pending/in-progress/done): " filter_value
            filter_field=3
            ;;
        2)
            read -rp "  Priority (high/medium/low): " filter_value
            filter_field=4
            ;;
    esac

    print_table_header

    local count=0
    while IFS="$DELIMITER" read -r id title status priority due_date; do
        if [[ -n "$filter_field" && "$filter_value" != "" ]]; then
            # Compare the relevant field
            local field_val
            case "$filter_field" in
                3) field_val="$status"   ;;
                4) field_val="$priority" ;;
            esac
            [[ "${field_val,,}" != "${filter_value,,}" ]] && continue
        fi
        print_task_row "$id" "$title" "$status" "$priority" "$due_date"
        (( count++ ))
    done < "$TASKS_FILE"

    echo -e "  ${DIM}$(printf '%0.s─' {1..78})${RESET}"
    echo -e "  ${DIM}${count} task(s) displayed.${RESET}"
    pause
}

# ═════════════════════════════════════════════════════════════════════════════
# 3. UPDATE TASK
# ═════════════════════════════════════════════════════════════════════════════
update_task() {
    header "Update Task"

    read -rp "  Enter Task ID to update: " upd_id
    if ! id_exists "$upd_id"; then
        error "Task ID #${upd_id} not found."
        pause; return
    fi

    # Read current values
    local line
    line=$(grep "^${upd_id}${DELIMITER}" "$TASKS_FILE")
    IFS="$DELIMITER" read -r _ cur_title cur_status cur_priority cur_due <<< "$line"

    echo -e "\n  Current values:"
    print_table_header
    print_task_row "$upd_id" "$cur_title" "$cur_status" "$cur_priority" "$cur_due"
    echo

    # Title
    read -rp "  New title       [${cur_title}]: " new_title
    new_title="${new_title:-$cur_title}"
    new_title="${new_title//[$DELIMITER]/}"
    [[ -z "$new_title" ]] && new_title="$cur_title"

    # Status
    while true; do
        read -rp "  New status      [${cur_status}] (pending/in-progress/done): " new_status
        new_status="${new_status:-$cur_status}"
        if [[ "${new_status,,}" =~ ^(pending|in-progress|done)$ ]]; then
            new_status="${new_status,,}"; break
        else
            warn "Status must be: pending, in-progress, or done."
        fi
    done

    # Priority
    while true; do
        read -rp "  New priority    [${cur_priority}] (high/medium/low): " new_priority
        new_priority="${new_priority:-$cur_priority}"
        if [[ "${new_priority,,}" =~ ^(high|medium|low)$ ]]; then
            new_priority="${new_priority,,}"; break
        else
            warn "Priority must be: high, medium, or low."
        fi
    done

    # Due date
    while true; do
        read -rp "  New due date    [${cur_due}] (YYYY-MM-DD): " new_due
        new_due="${new_due:-$cur_due}"
        if validate_date "$new_due"; then
            break
        else
            warn "Invalid date format. Use YYYY-MM-DD."
        fi
    done

    # Build new line and replace in file
    local new_line="${upd_id}${DELIMITER}${new_title}${DELIMITER}${new_status}${DELIMITER}${new_priority}${DELIMITER}${new_due}"
    # Escape delimiter for sed
    local escaped_line
    escaped_line=$(echo "$new_line" | sed 's/[\/&]/\\&/g')
    sed -i "s|^${upd_id}${DELIMITER}.*|${escaped_line}|" "$TASKS_FILE"

    success "Task #${upd_id} updated successfully."
    pause
}

# ═════════════════════════════════════════════════════════════════════════════
# 4. DELETE TASK
# ═════════════════════════════════════════════════════════════════════════════
delete_task() {
    header "Delete Task"

    read -rp "  Enter Task ID to delete: " del_id
    if ! id_exists "$del_id"; then
        error "Task ID #${del_id} not found."
        pause; return
    fi

    local line
    line=$(grep "^${del_id}${DELIMITER}" "$TASKS_FILE")
    IFS="$DELIMITER" read -r _ d_title d_status d_priority d_due <<< "$line"

    print_table_header
    print_task_row "$del_id" "$d_title" "$d_status" "$d_priority" "$d_due"
    echo

    read -rp "  $(echo -e "${BRED}Are you sure you want to delete this task? (yes/no):${RESET} ")" confirm
    if [[ "${confirm,,}" == "yes" ]]; then
        sed -i "/^${del_id}${DELIMITER}/d" "$TASKS_FILE"
        success "Task #${del_id} deleted."
    else
        info "Deletion cancelled."
    fi
    pause
}

# ═════════════════════════════════════════════════════════════════════════════
# 5. SEARCH TASKS
# ═════════════════════════════════════════════════════════════════════════════
search_tasks() {
    header "Search Tasks"

    read -rp "  Enter keyword (supports regex): " keyword
    if [[ -z "$keyword" ]]; then
        warn "Search keyword cannot be empty."
        pause; return
    fi

    print_table_header

    local count=0
    while IFS="$DELIMITER" read -r id title status priority due_date; do
        if echo "$title" | grep -Eiq "$keyword" 2>/dev/null; then
            print_task_row "$id" "$title" "$status" "$priority" "$due_date"
            (( count++ ))
        fi
    done < "$TASKS_FILE"

    echo -e "  ${DIM}$(printf '%0.s─' {1..78})${RESET}"
    echo -e "  ${DIM}${count} task(s) found for \"${keyword}\".${RESET}"
    pause
}

# ═════════════════════════════════════════════════════════════════════════════
# 6. REPORTS
# ═════════════════════════════════════════════════════════════════════════════

# ── 6a. Task Summary ──────────────────────────────────────────────────────────
report_summary() {
    header "Report: Task Summary"

    local pending=0 inprogress=0 done_count=0 total=0

    while IFS="$DELIMITER" read -r _ _ status _ _; do
        case "$status" in
            pending)     (( pending++    )) ;;
            in-progress) (( inprogress++ )) ;;
            done)        (( done_count++ )) ;;
        esac
        (( total++ ))
    done < "$TASKS_FILE"

    echo -e "\n  ${WHITE}Status Breakdown${RESET}"
    echo -e "  ${DIM}──────────────────────────────${RESET}"
    # NOTE: printf %-Ns mis-counts ANSI escape codes as visible characters,
    # causing broken alignment. Fix: pad with plain text first, colour separately.
    echo -e "  $(printf '%-14s' 'pending')  $(colour_status pending)   ${YELLOW}${pending}${RESET}"
    echo -e "  $(printf '%-14s' 'in-progress')  $(colour_status in-progress) ${BLUE}${inprogress}${RESET}"
    echo -e "  $(printf '%-14s' 'done')  $(colour_status done)      ${GREEN}${done_count}${RESET}"
    echo -e "  ${DIM}──────────────────────────────${RESET}"
    echo -e "  ${WHITE}$(printf '%-14s' 'Total:')${RESET}                ${WHITE}${total}${RESET}"
    pause
}

# ── 6b. Overdue Tasks ─────────────────────────────────────────────────────────
report_overdue() {
    header "Report: Overdue Tasks"

    local today
    today=$(date "+%Y-%m-%d")
    local count=0

    print_table_header

    while IFS="$DELIMITER" read -r id title status priority due_date; do
        # Skip completed tasks
        [[ "$status" == "done" ]] && continue
        # Compare dates lexicographically (YYYY-MM-DD format is safely comparable)
        if [[ "$due_date" < "$today" ]]; then
            print_task_row "$id" "$title" "$status" "$priority" \
                "$(echo -e "${BRED}${due_date}${RESET}")"
            (( count++ ))
        fi
    done < "$TASKS_FILE"

    echo -e "  ${DIM}$(printf '%0.s─' {1..78})${RESET}"
    if (( count == 0 )); then
        success "No overdue tasks!"
    else
        warn "${count} overdue task(s) found."
    fi
    pause
}

# ── 6c. Priority Report ───────────────────────────────────────────────────────
report_priority() {
    header "Report: Tasks by Priority"

    for prio in high medium low; do
        echo -e "\n  $(colour_priority "$prio") ${DIM}─────────────────────────────────${RESET}"
        local count=0
        while IFS="$DELIMITER" read -r id title status priority due_date; do
            if [[ "$priority" == "$prio" ]]; then
                printf "  ${WHITE}%-5s${RESET}  %-28s  %-17s  %s\n" \
                    "$id" "$title" "$(colour_status "$status")" "$due_date"
                (( count++ ))
            fi
        done < "$TASKS_FILE"
        (( count == 0 )) && echo -e "  ${DIM}No tasks with this priority.${RESET}"
    done

    pause
}

# ── Reports sub-menu ──────────────────────────────────────────────────────────
reports_menu() {
    while true; do
        header "Reports"
        echo -e "  ${WHITE}1${RESET}. Task Summary (counts per status)"
        echo -e "  ${WHITE}2${RESET}. Overdue Tasks"
        echo -e "  ${WHITE}3${RESET}. Priority Report"
        echo -e "  ${WHITE}0${RESET}. Back to Main Menu"
        echo
        read -rp "  Choice: " rep_choice
        case "$rep_choice" in
            1) report_summary  ;;
            2) report_overdue  ;;
            3) report_priority ;;
            0) return          ;;
            *) warn "Invalid choice. Please try again." ;;
        esac
    done
}

# ═════════════════════════════════════════════════════════════════════════════
# BONUS: SORT TASKS
# ═════════════════════════════════════════════════════════════════════════════
sort_tasks() {
    header "Sort Tasks"
    echo -e "  Sort by:  ${WHITE}1${RESET} Due Date (asc)   ${WHITE}2${RESET} Due Date (desc)"
    echo -e "            ${WHITE}3${RESET} Priority         ${WHITE}4${RESET} Status"
    read -rp "  Choice: " sort_choice

    local sorted
    case "$sort_choice" in
        1) sorted=$(sort -t"$DELIMITER" -k5,5 "$TASKS_FILE")  ;;
        2) sorted=$(sort -t"$DELIMITER" -k5,5r "$TASKS_FILE") ;;
        3)
            # Map priority to a number for sorting: high=1, medium=2, low=3
            sorted=$(awk -F"$DELIMITER" '
                {
                    p=$4
                    if (p=="high")   n=1
                    else if (p=="medium") n=2
                    else             n=3
                    print n SUBSEP $0
                }' "$TASKS_FILE" | sort -t$'\034' -k1,1n | cut -d$'\034' -f2-)
            ;;
        4) sorted=$(sort -t"$DELIMITER" -k3,3 "$TASKS_FILE") ;;
        *) warn "Invalid choice."; pause; return ;;
    esac

    print_table_header
    local count=0
    while IFS="$DELIMITER" read -r id title status priority due_date; do
        print_task_row "$id" "$title" "$status" "$priority" "$due_date"
        (( count++ ))
    done <<< "$sorted"

    echo -e "  ${DIM}$(printf '%0.s─' {1..78})${RESET}"
    echo -e "  ${DIM}${count} task(s) displayed.${RESET}"
    pause
}

# ═════════════════════════════════════════════════════════════════════════════
# BONUS: EXPORT TO CSV
# ═════════════════════════════════════════════════════════════════════════════
export_csv() {
    header "Export to CSV"

    echo "ID,Title,Status,Priority,DueDate" > "$EXPORT_FILE"
    while IFS="$DELIMITER" read -r id title status priority due_date; do
        # Wrap title in quotes in case it contains commas
        printf '"%s","%s","%s","%s","%s"\n' \
            "$id" "$title" "$status" "$priority" "$due_date" >> "$EXPORT_FILE"
    done < "$TASKS_FILE"

    success "Tasks exported to ${EXPORT_FILE}"
    pause
}

# ═════════════════════════════════════════════════════════════════════════════
# MAIN MENU
# ═════════════════════════════════════════════════════════════════════════════
main_menu() {
    while true; do
        clear
        echo -e "${BBLUE}"
        echo "  ╔══════════════════════════════════════════╗"
        echo "  ║        BASH TASK MANAGER  v1.0           ║"
        echo "  ╚══════════════════════════════════════════╝"
        echo -e "${RESET}"
        echo -e "  ${BCYAN}── TASKS ──────────────────────────────────${RESET}"
        echo -e "  ${WHITE}1${RESET}. Add Task"
        echo -e "  ${WHITE}2${RESET}. List Tasks"
        echo -e "  ${WHITE}3${RESET}. Update Task"
        echo -e "  ${WHITE}4${RESET}. Delete Task"
        echo -e "  ${WHITE}5${RESET}. Search Tasks"
        echo -e "  ${BCYAN}── TOOLS ───────────────────────────────────${RESET}"
        echo -e "  ${WHITE}6${RESET}. Reports"
        echo -e "  ${WHITE}7${RESET}. Sort Tasks"
        echo -e "  ${WHITE}8${RESET}. Export to CSV"
        echo -e "  ${BCYAN}────────────────────────────────────────────${RESET}"
        echo -e "  ${WHITE}0${RESET}. Exit"
        echo

        # Quick stats bar
        if [[ -s "$TASKS_FILE" ]]; then
            local total pending done_c
            total=$(wc -l < "$TASKS_FILE")
            pending=$(grep -c "${DELIMITER}pending${DELIMITER}" "$TASKS_FILE" 2>/dev/null || echo 0)
            done_c=$(grep -c "${DELIMITER}done${DELIMITER}" "$TASKS_FILE" 2>/dev/null || echo 0)
            echo -e "  ${DIM}Tasks: ${total} total  │  ${YELLOW}${pending} pending${RESET}${DIM}  │  ${GREEN}${done_c} done${RESET}"
        fi

        echo
        read -rp "  $(echo -e "${WHITE}Enter choice:${RESET} ")" choice

        case "$choice" in
            1) add_task     ;;
            2) list_tasks   ;;
            3) update_task  ;;
            4) delete_task  ;;
            5) search_tasks ;;
            6) reports_menu ;;
            7) sort_tasks   ;;
            8) export_csv   ;;
            0)
                echo -e "\n  ${BGREEN}Goodbye!${RESET}\n"
                exit 0
                ;;
            *)
                warn "Invalid choice. Please select 0–8."
                sleep 1
                ;;
        esac
    done
}

# ═════════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ═════════════════════════════════════════════════════════════════════════════
init_file
main_menu
