#!/usr/bin/env bash
# Claude Code statusLine
# Format: <model>  <reasoning>  ctx:<used>%  │  <directory> on  <branch> <git_status>

input=$(cat)

# ── Model ────────────────────────────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // ""')
# Bedrock reports the inference profile ARN as id and name: map the team's profile ids (see justfile) back.
model_id=$(jq -r '.model.id // ""' <<< "$input")
case "$model_id" in
  *wv58qt9e27ff) model_id=sonnet-5-5; model="Sonnet 5.5" ;;
  *vto136h01rmd) model_id=opus-5-5;   model="Opus 5.5" ;;
  *6pulmnz1kg52) model_id=haiku-5-5;  model="Haiku 5.5" ;;
esac

# ── Reasoning effort (capitalised: low→Low, high→High, xhigh→Xhigh) ───────────
effort=$(echo "$input" | jq -r '.effort.level // empty')
if [[ -n "$effort" ]]; then
  effort="$(tr '[:lower:]' '[:upper:]' <<< "${effort:0:1}")${effort:1}"
fi

# ── Context used % ────────────────────────────────────────────────────────────
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
# Tokens the next call re-sends (last call's input + cache read + cache write + output), in k
ctx_k=$(jq -r '.context_window.current_usage // empty | ((.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.output_tokens // 0)) / 1000 | round' <<< "$input")

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

# ── Prompt cache (line 2) ─────────────────────────────────────────────────────
# List prices $/MTok: input output cache-read (platform.claude.com pricing, 2026-10-13).
# Cache writes: 5m = 1.25x input, 1h = 2x input. Re-check prices when models change.
case "$model_id" in
  *fable-5-1*)  p=(10 50 0.25) ;;
  *opus-5-5*)   p=(4 20 0.20) ;;
  *sonnet-5-5*) p=(2 10 0.10) ;;
  *haiku-5-5*)  p=(0.10 0.50 0.01) ;;  # ponytail: ignores Haiku's >100K-prompt tier (5x)
  *opus-5*)     p=(5 25 0.50) ;;
  *sonnet-5*)   p=(2 10 0.20) ;;
  *)            p=(0 0 0) ;;           # unknown model: $ figures hidden
esac

IFS='|' read -r c_warm c_seen c_ttl c_left c_hit c_miss c_cause c_tok next_warm next_cold sess_usd < <(
  jq -r --argjson pin "${p[0]}" --argjson pread "${p[2]}" '
    .prompt_cache as $c | if $c == null then empty else
    (if .fast_mode == true then 2 else 1 end) as $f   # fast mode: 2x every rate
    | ($pin*$f) as $in | ($pread*$f) as $rd
    | ($in * (if $c.ttl == "1h" then 2 else 1.25 end)) as $wr
    | [ $c.warm, $c.caching_observed, $c.ttl,
        (if $c.expires_at then ($c.expires_at - now | floor) else null end),
        (if $c.hit_ratio then ($c.hit_ratio * 100 | round) else null end),
        $c.misses, ($c.last_miss_cause.causes[0]? // null),
        $c.recache_tokens_if_cold,
        (if $c.recache_tokens_if_cold then $c.recache_tokens_if_cold*$rd/1e6 else null end),
        (if $c.recache_tokens_if_cold then $c.recache_tokens_if_cold*$wr/1e6 else null end),
        .cost.total_cost_usd ]
    | map(if . == null then "" else tostring end) | join("|") end' <<< "$input")

# Row 2: cache now (state, CR = cache-read price, CW = cache-write price) │ session so far: ↵ turns, ⇵ API calls, ◉ hit, ↩ last turn, ≡ total cost.
warm=false
[[ "$c_warm" == "true" && -n "$c_left" ]] && (( c_left > 0 )) && warm=true
priced=$([[ "${p[0]}" != 0 ]] && echo true || echo false)

# ↵ = prompts typed; ⇵ = API responses (tokscale's messageCount); ✎ = output tokens so far;
# ↩ = cost of the current turn so far, else the previous one. Main conversation only: background
# helper calls are in ≡ but not in the transcript, so ↩ can trail the change in ≡.
transcript=$(jq -r '.transcript_path // empty' <<< "$input")
fast=$([[ "$(jq -r '.fast_mode // false' <<< "$input")" == true ]] && echo 2 || echo 1)
turns="" msgs="" out_tok="" turn_usd=""
if [[ -f "$transcript" ]]; then
  IFS=$'\t' read -r turns msgs out_tok turn_usd < <(jq -rs --argjson pin "${p[0]}" --argjson pout "${p[1]}" --argjson pread "${p[2]}" --argjson f "$fast" '
    def prompt: .type == "user" and (.isMeta | not) and (.isSidechain | not) and (.message.content
      | (type == "string" and length > 0 and (startswith("<command-") | not) and (startswith("<local-command") | not))
        or (type == "array" and all(.[]; .type != "tool_result")));
    def calls: [.[] | select(.type == "assistant" and (.isSidechain | not) and .message.usage)]
      | group_by(.message.id) | map(last.message.usage);   # one transcript line per content block
    def usd: ((.input_tokens // 0) * $pin + (.cache_read_input_tokens // 0) * $pread + (.output_tokens // 0) * $pout
      + (if .cache_creation then (.cache_creation.ephemeral_5m_input_tokens // 0) * $pin * 1.25
                                 + (.cache_creation.ephemeral_1h_input_tokens // 0) * $pin * 2
         else (.cache_creation_input_tokens // 0) * $pin * 1.25 end)) * $f / 1e6;
    ([to_entries[] | select(.value | prompt) | .key]) as $prompts
    | [ ($prompts | length),
        (calls | length),
        (calls | map(.output_tokens // 0) | add // 0),
        ((($prompts | last) // -1) as $l | (.[$l + 1:] | calls) as $cur
          | if ($cur | length) > 0 then $cur                        # the turn so far,
            else .[(($prompts[-2]) // -1) + 1:$l] | calls end       # else the previous turn
          | map(usd) | add // 0) ]
    | @tsv' "$transcript" 2>/dev/null)
  tools=$(jq -rs '[.[] | select(.type == "assistant" and (.isSidechain | not)) | .message.content[]? | select(.type == "tool_use") | .id] | unique | length' "$transcript" 2>/dev/null)
fi

# Prices use Anthropic's billing names: read = cache hit (warm), write = full re-cache (cold).
# Muted 256-color tones, kept apart from the green/yellow/blue state colors.
c_read='\033[38;5;108m' c_write='\033[38;5;110m' reset='\033[0m' sep=' │ '
cache_part=""
if [[ "$c_seen" == "true" ]]; then
  if $warm; then
    ttl_s=$([[ "$c_ttl" == "1h" ]] && echo 3600 || echo 300)
    left=$( (( c_left >= 60 )) && echo "$((c_left / 60))m" || echo "<1m" )
    color=$( (( c_left * 5 < ttl_s )) && echo 33 || echo "38;5;151" )   # pale green; yellow in the last 20% of TTL
    cache_part=$(printf '\033[%sm● Warm %s\033[0m' "$color" "$left")
    if $priced && [[ -n "$c_tok" ]]; then
      cache_part+=$(printf "${sep}${c_read}CR:\$%.2f${reset} ${c_write}CW:\$%.2f${reset}" "$next_warm" "$next_cold")
    fi
  else
    cache_part=$(printf '\033[34m● Cold\033[0m')
    if $priced && [[ -n "$c_tok" ]]; then
      cache_part+=$(printf "${sep}${c_write}CW:\$%.2f${reset}" "$next_cold")
    fi
  fi
fi

session_part=""
[[ -n "$turns" ]] && session_part+=$'\033[1m↵\033[22m'" $turns "$'\033[1m⇵\033[22m'" $msgs"
[[ -n "$tools" && "$tools" != 0 ]] && session_part+="${session_part:+ }"$'\033[1m⚒\033[22m'" $tools"
[[ "$c_seen" == "true" && -n "$c_hit" ]] && session_part+="${session_part:+ }◉ ${c_hit}%"
if [[ -n "$c_miss" ]] && (( c_miss > 0 )); then
  session_part+=$(printf ' \033[33m✗%s%s\033[0m' "$c_miss" "${c_cause:+ $c_cause}")
fi
$priced && [[ -n "$turn_usd" ]] && session_part+=$(printf '%s↩ $%.2f' "${session_part:+ }" "$turn_usd")
[[ -n "$sess_usd" ]] && session_part+=$(printf '%s≡ $%.2f' "${session_part:+ }" "$sess_usd")


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
if [[ -n "$ctx_used" && -n "$ctx_k" ]]; then
  ctx_int=$(printf '%.0f' "$ctx_used")
  if (( ctx_int > 80 )); then
    out+=$(printf ' \033[31mctx:%sk\033[0m' "$ctx_k")
  else
    out+=$(printf ' ctx:%sk' "$ctx_k")
  fi
fi

# Output tokens so far (main conversation)
if [[ -n "$out_tok" ]]; then
  out+=$( (( out_tok >= 1000 )) && printf ' ✎ %dk' "$((out_tok / 1000))" || printf ' ✎ %d' "$out_tok")
fi

# Separator
out+=" │ "

# Git branch (purple)
if [[ -n "$git_branch" ]]; then
  out+=$(printf '\033[35mon  %s\033[0m' "$git_branch")
fi

# Git status indicators (yellow)
if [[ -n "$git_status_str" ]]; then
  out+=$(printf ' \033[33m%s\033[0m' "$git_status_str")
fi

# Lines Claude added / removed across the whole session, main + subagents (hidden while both are 0).
# Read from the transcript, not .cost.total_lines_*.
lines_add=0 lines_del=0
if [[ -f "$transcript" ]]; then
  sub_dir="${transcript%.jsonl}/subagents"
  read -r lines_add lines_del < <(cat "$transcript" "$sub_dir"/*.jsonl 2>/dev/null | jq -rn '
    [inputs | select((.toolUseResult | type) == "object")
      | .toolUseResult
      | if .type == "create" then {a: (.content | split("\n") | length), d: 0}
        else (.structuredPatch // [] | map(.lines[]) | {a: map(select(startswith("+"))) | length, d: map(select(startswith("-"))) | length}) end]
    | "\(map(.a) | add // 0) \(map(.d) | add // 0)"')
fi
if (( lines_add > 0 || lines_del > 0 )); then
  out+=$(printf ' \033[32m+%d\033[0m \033[31m−%d\033[0m' "$lines_add" "$lines_del")
fi

printf '%s' "$out"
if [[ -n "$cache_part" ]]; then printf '\n%s%s' "$cache_part" "${session_part:+$sep$session_part}"; fi   # exit 0: Claude Code hides the line on non-zero
