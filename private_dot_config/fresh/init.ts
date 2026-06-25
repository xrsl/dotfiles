// freshdiff — open fresh straight into a git diff view when FRESH_DIFF is set.
// Driven by the `freshdiff` shell function; plain `fresh` is unaffected.
//   FRESH_DIFF=1|review  -> working-tree review (uncommitted changes, magit-style)
//   FRESH_DIFF=range     -> range review of FRESH_REVIEW_RANGE (e.g. main..HEAD):
//                           changed-files list + Enter = side-by-side (the PR view)
//   FRESH_DIFF=side      -> side-by-side diff of the opened file
//   FRESH_DIFF=head      -> live diff of the buffer vs git HEAD
//   FRESH_DIFF=disk      -> live diff vs the on-disk version
//   FRESH_DIFF=branch    -> live diff vs the default branch
editor.on("plugins_loaded", () => {
  const mode = editor.getEnv("FRESH_DIFF");
  if (!mode) return;

  // These diff views are plugin-defined *modes* whose bindings replace the
  // global/normal context, so config.json `keybindings` can't reach them. In
  // the throwaway freshdiff flow we want Esc (and q) to fully exit fresh, so we
  // redefine the modes here — this runs after the diff plugin's load-time
  // defineMode, so ours wins. Bindings mirror fresh's built-ins with the
  // cancel/close keys repointed at force_quit; if a fresh update adds review
  // keys, copy them here too (unbound keys just no-op).
  const QUIT = "force_quit";

  // review-mode powers BOTH the working-tree review (start_review_diff) and the
  // range review (start_review_range). Override once: keep every built-in key,
  // repoint Esc/q to force_quit. Enter stays review_enter_dispatch, which
  // drills a changed line into the side-by-side view.
  const defineReviewMode = () => editor.defineMode("review-mode", [
    ["Up", "review_nav_up"], ["Down", "review_nav_down"],
    ["k", "review_nav_up"], ["j", "review_nav_down"],
    ["PageUp", "review_page_up"], ["PageDown", "review_page_down"],
    ["Home", "move_line_start"], ["End", "move_line_end"],
    ["n", "review_next_hunk"], ["p", "review_prev_hunk"],
    ["Tab", "review_toggle_file_collapse"],
    ["z a", "review_collapse_all"], ["z r", "review_expand_all"],
    ["v", "review_visual_start"],
    ["Enter", "review_enter_dispatch"],
    ["M-o", "review_open_working_file"],
    ["]", "review_next_comment"], ["[", "review_prev_comment"],
    ["`", "review_focus_comments"],
    ["s", "review_stage_scope"], ["u", "review_unstage_scope"],
    ["d", "review_discard_file"],
    ["S", "review_stage_file"], ["U", "review_unstage_file"],
    ["D", "review_discard_file_only"],
    ["r", "review_refresh"],
    ["c", "review_add_comment"],
    ["N", "review_edit_note"],
    ["x", "review_delete_comment"],
    ["e", "review_export_session"],
    // repointed: a single press exits the throwaway diff view.
    ["Escape", QUIT],
    ["q", QUIT],
  ], true);

  if (mode === "range") {
    // PR view: all changes across FRESH_REVIEW_RANGE (e.g. main..HEAD) as a
    // flattened diff — same file/hunk review as the working-tree review, so the
    // changed-files list shows on the left and Enter on a changed line opens
    // side-by-side. The diff plugin registers a global prompt_confirmed
    // listener for prompt_type "review-range" that runs the review, so we open
    // that prompt pre-filled with the range and confirm it immediately — no
    // visible prompt, deterministic (no async-timing race).
    defineReviewMode();
    const range = editor.getEnv("FRESH_REVIEW_RANGE") || "HEAD";
    editor.startPromptWithInitial("Review range:", "review-range", range);
    editor.executeAction("prompt_confirm");
    return;
  }

  if (mode === "side" || mode === "head" || mode === "disk" || mode === "branch") {
    // diff-view: side-by-side + live diffs (only Enter / Alt+O were bound).
    editor.defineMode("diff-view", [
      ["Enter", "review_diff_open_at_cursor"],
      ["M-o", "review_diff_open_working_at_cursor"],
      ["Escape", QUIT],
      ["q", QUIT],
    ], true);
    const action =
      mode === "side" ? "side_by_side_diff_current_file" :
      mode === "head" ? "live_diff_vs_head" :
      mode === "disk" ? "live_diff_vs_disk" :
                        "live_diff_vs_default_branch";
    try {
      editor.executeAction(action);
    } catch (e) {
      editor.setStatus("freshdiff: " + e);
    }
    return;
  }

  // default: working-tree review of uncommitted changes.
  defineReviewMode();
  try {
    editor.executeAction("start_review_diff");
  } catch (e) {
    editor.setStatus("freshdiff: " + e);
  }
});
