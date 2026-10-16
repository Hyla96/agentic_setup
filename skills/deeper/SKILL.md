---
name: deeper
description: "Turn a task or prompt into a deeper version of itself, not a bigger one: say what a top professional in the field would do that the user isn't asking for, the raw material they'd start from, the methods and tools they'd use, and what outside evidence would show the result is right, then rewrite the prompt to ask for exactly that. Use when the user says deeper, go deeper, deepen this, or invokes /deeper on a prompt."
user-invocable: true
---

# Deeper

I want a deeper version of this task, not a bigger one. Before rewriting it:

1. Say what a top professional in this field would do here that I'm not asking for.
2. Name the rawest material they would start from instead of what has already been digested for me.
3. Name the specific methods and tools they would use.
4. Say what, other than you or me, would show the result is right.

Then rewrite my prompt to ask for exactly that.

## How to apply

- The task is `$ARGUMENTS`. If that is empty, use the most recent task or prompt in the conversation.
- Rewrite the prompt only. Do not start doing the task.
- Deeper means more rigour on the same question. Do not add new deliverables or widen the scope.
- Answer each of the four points specifically for this task. A generic answer such as "use primary sources" or "get expert review" doesn't count: name the actual source, method, tool, or check.
- For point 4, name something outside the conversation that could show the result is wrong: data, a test, a measurement, a benchmark, an independent source, or a named reviewer role.
- Output the four answers first, then the rewritten prompt in a fenced block so it can be copied as-is.
