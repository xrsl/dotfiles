-- Toggle between the current and the previous session, like cmd+tab for apps.
-- Needs a server with focus_history.reverse (API revision 19+).
rex.action{
  name = "last_session",
  title = "Last Session",
  run = function(ctx)
    local r = rex.call("focus_history.reverse", { not_session_id = ctx.session_id })
    if r and r.reversed then
      rex.client.queue("session.select", { session_id = r.session_id, window_id = r.window_id })
    end
  end,
}
rex.bind("alt+tab", "last_session")
