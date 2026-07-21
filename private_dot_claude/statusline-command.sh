#!/usr/bin/env bash
# Claude Code statusLine
# Format: <model>  <reasoning>  ctx:<used>%  │  <directory> on  <branch> <git_status>

input=$(cat)

# ── Model ────────────────────────────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // ""')

# ── Reasoning effort (capitalised: low→Low, high→High, xhigh→Xhigh) ───────────
effort=$(echo "$input" | jq -r '.effort.level // empty')
if [[ -n "$effort" ]]; then
  effort="$(tr '[:lower:]' '[:upper:]' <<< "${effort:0:1}")${effort:1}"
fi

# ── Context used % ────────────────────────────────────────────────────────────
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# ── Git info (branch + status) ────────────────────────────────────────────────
git_branch=""
git_status_str=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

  upstream=$(git -C "$cwd" rev-parse --abbrev-ref '@{u}' 2>/dev/null)
  if [[ -n "$upstream" ]]; then
    ahead=$(git -C "$cwd" rev-list --count "@{u}..HEAD" 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count "HEAD..@{u}" 2>/dev/null || echo 0)
    (( ahead > 0 && behind > 0 )) && git_status_str+="⇕⇡${ahead}⇣${behind} "
    (( ahead > 0 && behind == 0 )) && git_status_str+="⇡${ahead} "
    (( behind > 0 && ahead == 0 )) && git_status_str+="⇣${behind} "
  fi

  while IFS= read -r line; do
    xy="${line:0:2}"
    case "$xy" in
      \?\?) git_status_str+="? " ;;
      ?M|M?)  git_status_str+="! " ;;
      ?A|A?|?D|D?) git_status_str+="+ " ;;
      R?) git_status_str+="» " ;;
    esac
  done < <(git -C "$cwd" status --porcelain 2>/dev/null | head -20)

  git_status_str=$(echo "$git_status_str" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)
fi

# ── Assemble output ───────────────────────────────────────────────────────────
out=""

# Model (cyan)
if [[ -n "$model" ]]; then
  out+=$(printf '\033[36m%s\033[0m' "$model")
fi

# Reasoning effort (green)
if [[ -n "$effort" ]]; then
  out+=$(printf ' \033[32m%s\033[0m' "$effort")
fi

# Context used % (red when above 80%)
if [[ -n "$ctx_used" ]]; then
  ctx_int=$(printf '%.0f' "$ctx_used")
  if (( ctx_int > 80 )); then
    out+=$(printf ' \033[31mctx:%d%%\033[0m' "$ctx_int")
  else
    out+=$(printf ' ctx:%d%%' "$ctx_int")
  fi
fi

# Separator
out+=" │ "

# Git branch (purple)
if [[ -n "$git_branch" ]]; then
  out+=$(printf ' \033[35mon  %s\033[0m' "$git_branch")
fi

# Git status indicators (yellow)
if [[ -n "$git_status_str" ]]; then
  out+=$(printf ' \033[33m%s\033[0m' "$git_status_str")
fi

printf '%s' "$out"
