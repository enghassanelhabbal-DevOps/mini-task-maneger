# 📋 Bash Task Manager

A fully-featured, interactive **Task Management System** built entirely in Bash. Manage your daily tasks from the terminal with a colourful menu-driven interface, full CRUD operations, filtering, reporting, and more.

---

## 🚀 Quick Start

```bash
bash task_manager.sh
```

No installation required. Just run it — the data file (`tasks.txt`) is created automatically on first launch.

---

## ✨ Features

| Category | Feature |
|----------|---------|
| **CRUD** | Add, List, Update, Delete tasks |
| **Search** | Regex-powered keyword search on task titles |
| **Filter** | Filter tasks by status or priority |
| **Sort** | Sort by due date (asc/desc), priority, or status |
| **Reports** | Summary counts, overdue tasks, priority grouping |
| **Export** | One-click CSV export |
| **UI** | Full ANSI colour output, live stats bar on menu |
| **Validation** | Non-empty titles, enum checks, calendar-valid dates |

---

## 📁 File Structure

```
task_manager.sh      # Main script (single file, self-contained)
tasks.txt            # Auto-created task database (pipe-delimited)
tasks_export.csv     # Generated when you use the Export feature
```

### Data Format

Each task is stored as a single pipe-delimited line in `tasks.txt`:

```
ID|Title|Status|Priority|DueDate
```

**Example:**
```
1|Fix login bug|in-progress|high|2025-06-15
2|Write unit tests|pending|medium|2025-06-20
3|Deploy to staging|done|high|2025-06-10
```

---

## 🗂️ Menu Overview

```
╔══════════════════════════════════════════╗
║        BASH TASK MANAGER  v1.0           ║
╚══════════════════════════════════════════╝

── TASKS ───────────────────────────────────
  1. Add Task
  2. List Tasks
  3. Update Task
  4. Delete Task
  5. Search Tasks

── TOOLS ───────────────────────────────────
  6. Reports
  7. Sort Tasks
  8. Export to CSV
────────────────────────────────────────────
  0. Exit
```

---

## 📖 Usage Guide

### 1 — Add Task

Prompts for **title**, **priority**, and **due date**. The system auto-generates a unique ID and sets the status to `pending`.

```
Title: Fix login bug
Priority (high/medium/low): high
Due Date (YYYY-MM-DD): 2025-06-15
✔  Task #1 "Fix login bug" added successfully.
```

### 2 — List Tasks

Displays all tasks in a formatted table. Optionally filter by:
- **Status** — `pending` / `in-progress` / `done`
- **Priority** — `high` / `medium` / `low`

### 3 — Update Task

Enter a task ID and modify any field. Press **Enter** to keep the current value.

```
Enter Task ID to update: 1
New title       [Fix login bug]:          ← kept
New status      [pending]: in-progress
New priority    [high]:                   ← kept
New due date    [2025-06-15]:             ← kept
```

### 4 — Delete Task

Shows a preview of the task and asks for `yes` confirmation before deleting.

### 5 — Search Tasks

Supports plain text and **regular expressions** against task titles.

```
Enter keyword (supports regex): bug|error|fix
```

### 6 — Reports

| Report | Description |
|--------|-------------|
| **Task Summary** | Count of tasks per status |
| **Overdue Tasks** | Tasks past due date with status ≠ `done` |
| **Priority Report** | All tasks grouped by high / medium / low |

### 7 — Sort Tasks

| Option | Sort |
|--------|------|
| 1 | Due Date ascending |
| 2 | Due Date descending |
| 3 | Priority (high → medium → low) |
| 4 | Status alphabetically |

### 8 — Export to CSV

Exports all tasks to `tasks_export.csv` in standard comma-separated format with a header row.

---

## ✅ Input Validation

| Field | Rule |
|-------|------|
| **Title** | Must not be empty |
| **Priority** | Must be exactly `high`, `medium`, or `low` |
| **Due Date** | Must match `YYYY-MM-DD` and be a calendar-valid date |
| **Status** | Must be `pending`, `in-progress`, or `done` |
| **Task ID** | Must exist in the file before update or delete |

---

## 🎨 Colour Legend

| Colour | Meaning |
|--------|---------|
| 🔴 Red | High priority / overdue dates |
| 🟡 Yellow | Medium priority / pending status |
| 🔵 Blue | In-progress status |
| 🟢 Green | Low priority / done status |

---

## 🛠️ Requirements

- **Bash** 4.0+ (pre-installed on Linux; macOS users may need `brew install bash`)
- **Standard Unix tools:** `awk`, `sed`, `grep`, `date`, `sort` — all included in any Linux/macOS system

> **macOS note:** Date validation uses a `date -j` fallback for macOS compatibility alongside the Linux `date -d` syntax.

---

## 🧰 Internal Tools Used

| Tool | Purpose |
|------|---------|
| `awk` | Field processing, ID generation, priority mapping for sort |
| `sed` | In-place line replacement and deletion |
| `grep` | Searching, filtering, ID existence checks |
| `sort` | Sorting tasks by various fields |
| `date` | Date validation and overdue comparison |
| `read` | Interactive user input |
| ANSI codes | Coloured terminal output |

---

## 📝 Notes

- Task IDs are **auto-incremented** and never reused after deletion.
- The **pipe character `|`** is reserved as a delimiter — it is automatically stripped from any user-entered title.
- Date comparisons for overdue detection use **lexicographic string comparison** on `YYYY-MM-DD`, which is safe and requires no external date libraries.
- All operations return to the main menu after completion.

---

## 📄 License

MIT — free to use, modify, and distribute.
