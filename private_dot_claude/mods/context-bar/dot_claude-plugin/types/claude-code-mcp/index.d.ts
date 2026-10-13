// The inputs of the MCP tools the session had connected when this mod
// was last saved, from each server's tools/list inputSchema.
// Merges into the engine's ToolCallInput (types/ McpToolInputs) so
// `e.tool === "mcp__<server>__<tool>"` narrows to the tool's arguments.
// Written again at a save of the mod with a server connected.
export {}
declare module 'claude-code' {
  interface McpToolInputs {
    /** Open Plannotator, the browser review UI, for the user, and return at once. Also lists and closes the reviews opened in this conversation (by this tool or the user's /plannotator-* commands). - action "annotate": annotate a file (markdown, text, config, HTML), a folder, or a URL; `target` is required. Pass a list as `target` to review several files together, in the order you want them read. `gate: true` adds an Approve button for an explicit sign-off. `options.markdown: true` converts HTML or a URL to markdown first. - action "review": review code changes; `target` is an optional repository directory or a GitHub/GitLab/Bitbucket pull request URL (default: the current repository). `options.base` sets the compare branch or ref (git only). - action "last": annotate your own last assistant message; no target. - action "list": the reviews opened in this conversation that are still open, one line each: session id, what it shows, url, age, state, and how many comments the reviewer has not sent yet. - action "close": close a review opened in this conversation that is no longer needed; `session` is its id (pn-...) or "all". Nothing is sent to you, and the reviewer's unsent comments stay saved as a draft. Plan reviews are not closed this way: they end with the reviewer's decision. Opening only opens the page and names its session id (pn-...). The reviewer's feedback arrives later as a message in this conversation that names the same id, so end your turn after opening and wait for it. Use this tool instead of running the `plannotator` CLI. Plan review is not done with this tool: it opens by itself when you exit plan mode. */
    mcp__plannotator__plannotator: {
      /** What to do: open a file/folder/URL to annotate, code changes or a PR to review, or your last message; list your open reviews; close one. */
      action: "annotate" | "review" | "last" | "list" | "close"
      /** annotate: the file, folder or URL (required), or a list of file paths to review together in that order. review: a repository directory or PR URL (optional). Other actions: not used. */
      target?: string | string[]
      /** annotate only: show an Approve button so the reviewer can sign off explicitly. */
      gate?: boolean
      options?: {
        /** review only: the branch or ref to compare against (git). */
        base?: string
        /** annotate only: convert an HTML file or URL to markdown before annotating. */
        markdown?: boolean
      }
      /** close: the session id (pn-...) of a review opened in this conversation, or "all". */
      session?: string
    }
  }
}
