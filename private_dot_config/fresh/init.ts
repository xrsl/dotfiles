// freshdiff — open fresh straight into a git diff view when FRESH_DIFF is set.
// Driven by the `freshdiff` shell function; plain `fresh` is unaffected.
//   FRESH_DIFF=1|review  -> repo-wide review diff (magit-style)
//   FRESH_DIFF=side      -> side-by-side diff of the opened file
//   FRESH_DIFF=head      -> live diff of the buffer vs git HEAD
//   FRESH_DIFF=disk      -> live diff vs the on-disk version
//   FRESH_DIFF=branch    -> live diff vs the default branch
//   FRESH_DIFF=pr        -> PR-branch review: all commits vs base/main (base..HEAD)
editor.on("plugins_loaded", () => {
  const mode = editor.getEnv("FRESH_DIFF");
  if (!mode) return;

  // These diff views are plugin-defined *modes* whose bindings replace the
  // global/normal context, so config.json `keybindings` can't reach them.
  // In the throwaway freshdiff flow we want Esc (and q) to fully exit fresh
  // back to herdr, so we redefine the modes here — this runs after the diff
  // plugin's load-time defineMode, so ours wins. Bindings mirror fresh's
  // built-ins with the cancel/close keys repointed at force_quit; if a fresh
  // update adds review keys, copy them here too (unbound keys just no-op).
  const QUIT = "force_quit";

  if (mode === "pr") {
    // review-branch: PR-style review of base..HEAD. Faithful copy of fresh's
    // built-in bindings (inherits Normal for arrows/PageUp/etc.), with q and
    // Esc (were review_branch_close_or_back) repointed to force_quit. The
    // nested file-view (Enter on a commit's file) keeps its own Esc=back.
    editor.defineMode("review-branch", [
      ["k", "move_up"],
      ["j", "move_down"],
      ["Return", "review_branch_enter"],
      ["Tab", "review_branch_tab"],
      ["r", "review_branch_refresh"],
      ["q", QUIT],
      ["Escape", QUIT],
    ], true, false, true);

    // start_review_branch opens a *blocking* prompt for the base ref, already
    // pre-filled with the repo's default branch (origin/HEAD -> main/master).
    // We don't want to confirm it by hand, so auto-accept the prefilled value:
    // confirm the first prompt that appears in this throwaway PR-review launch.
    // The prompt opens after an async git detection, so we can't confirm
    // synchronously — we react to it instead. If the event doesn't fire, this
    // degrades to the old behaviour (you press Enter), so it can't make things
    // worse.
    let basePromptAccepted = false;
    editor.on("prompt_changed", () => {
      if (basePromptAccepted) return;
      basePromptAccepted = true;
      editor.executeAction("prompt_confirm");
    });
  } else if (mode === "side" || mode === "head" || mode === "disk" || mode === "branch") {
    // diff-view: side-by-side + live diffs (only Enter / Alt+O were bound).
    editor.defineMode("diff-view", [
      ["Enter", "review_diff_open_at_cursor"],
      ["M-o", "review_diff_open_working_at_cursor"],
      ["Escape", QUIT],
      ["q", QUIT],
    ], true);
  } else {
    // review-mode: magit-style repo-wide review. Faithful copy of fresh's
    // built-in bindings, with Esc (was review_visual_cancel) and q (was
    // close) repointed to force_quit so a single key exits the viewer.
    editor.defineMode("review-mode", [
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
  }

  const action =
    mode === "side"   ? "side_by_side_diff_current_file" :
    mode === "head"   ? "live_diff_vs_head" :
    mode === "disk"   ? "live_diff_vs_disk" :
    mode === "branch" ? "live_diff_vs_default_branch" :
    mode === "pr"     ? "start_review_branch" :
                        "start_review_diff";
  try {
    editor.executeAction(action);
  } catch (e) {
    editor.setStatus("freshdiff: " + e);
  }
});
