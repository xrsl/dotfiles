// freshdiff — open fresh straight into a git diff/review view when FRESH_DIFF is set.
// Driven by the `freshdiff` shell function; plain `fresh` is unaffected.
//
//   (no FRESH_DIFF)      -> plain editor; open the file-explorer sidebar (IDE-style)
//   FRESH_DIFF=range     -> range review of FRESH_REVIEW_RANGE (e.g. origin/main..HEAD)
//   FRESH_DIFF=1|review  -> working-tree review (uncommitted changes)
//   FRESH_DIFF=side      -> side-by-side diff of the opened file
//   FRESH_DIFF=head      -> live diff vs git HEAD   (disk -> vs on-disk, branch -> vs default branch)
//
// NOTE: we deliberately do NOT redefine fresh's review modes here. defineMode()
// REPLACES a mode's bindings wholesale, and copying fresh's built-in review
// bindings means they drift out of date and silently break the advertised keys
// (n/p next/prev hunk, Tab focus, ,/. next/prev file). So we only LAUNCH the
// right view and let fresh own all the in-review keybindings.
editor.on("plugins_loaded", () => {
  const mode = editor.getEnv("FRESH_DIFF");

  if (!mode) {
    // Plain `e` (editor, no diff): show the file-explorer sidebar.
    editor.executeAction("focus_file_explorer");
    return;
  }

  if (mode === "range") {
    // PR view: review FRESH_REVIEW_RANGE (e.g. origin/main..HEAD). fresh's diff
    // plugin listens for a confirmed "review-range" prompt and runs the review,
    // so we open that prompt pre-filled with the range and confirm immediately —
    // no visible prompt. Native review keys (n/p/Tab/,/. ) then work normally.
    const range = editor.getEnv("FRESH_REVIEW_RANGE") || "HEAD";
    editor.startPromptWithInitial("Review range:", "review-range", range);
    editor.executeAction("prompt_confirm");
    // Default to split (side-by-side) layout. review_layout_split only sets a
    // layout flag and is idempotent, so we set it immediately (the render reads
    // the flag) plus one backup retry after the async review opens. Manual: `1`.
    // (The COMMENTS panel is structural in fresh's review layout and cannot be
    // hidden from here — no action/config removes it.)
    const split = () => { try { editor.executeAction("review_layout_split"); } catch (e) {} };
    split();
    editor.delay(700).then(split);
    return;
  }

  const action =
    mode === "side"   ? "side_by_side_diff_current_file" :
    mode === "head"   ? "live_diff_vs_head" :
    mode === "disk"   ? "live_diff_vs_disk" :
    mode === "branch" ? "live_diff_vs_default_branch" :
                        "start_review_diff";
  try {
    editor.executeAction(action);
  } catch (e) {
    editor.setStatus("freshdiff: " + e);
  }
});
