// `eh` (.zshrc): FRESH_REVIEW=worktree opens the uncommitted-changes review,
// any other value is a git range (A..B) for the range review.
editor.on("plugins_loaded", () => {
  const review = editor.getEnv("FRESH_REVIEW");
  if (!review) return;
  if (review === "worktree") {
    editor.executeAction("start_review_diff");
    return;
  }
  // fresh has no range-review action that takes an argument; its review plugin
  // listens for a confirmed "review-range" prompt, so fill one and confirm it.
  editor.startPromptWithInitial("Review range:", "review-range", review);
  editor.executeAction("prompt_confirm");
});
