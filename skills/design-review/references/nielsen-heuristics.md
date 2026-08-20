# Nielsen's heuristics — applied

The ten, with what to actually look for in a design review and the failure each one catches.

### 1. Visibility of system status
The user always knows what is happening. Feedback within 100ms of any interaction; a skeleton or
progress indicator for anything over 400ms; explicit confirmation after an action.
**Fails as:** a dead click, a saved change with no confirmation, an upload with no progress.

### 2. Match between the system and the real world
The user's vocabulary and mental model, not the database's. Information in a natural order.
**Fails as:** a raw enum on screen (`STATUS_PENDING_REVIEW`), internal jargon, a field named after a
column.

### 3. User control and freedom
An obvious way out of every state. Undo for reversible actions; cancel that actually cancels.
**Fails as:** a modal with no close, a wizard you cannot leave, a destructive action with no undo.

### 4. Consistency and standards
The same problem is solved the same way everywhere in the product; platform conventions respected.
**Fails as:** three different date pickers, "Delete" here and "Remove" there for the same thing.

### 5. Error prevention
Better than any error message. Constrain the input, confirm the destructive, disable the impossible.
**Fails as:** a free-text field where a select belongs; "Delete?" with an "OK" button that does not
name the object.

### 6. Recognition rather than recall
Options visible; the user should not have to remember something from a previous screen.
**Fails as:** an error message referring to a value that is no longer on screen; a code the user has
to memorize between steps.

### 7. Flexibility and efficiency of use
Shortcuts for the frequent user that do not confuse the new one. Sensible defaults; remembered
preferences.
**Fails as:** eight clicks for the action a power user does forty times a day.

### 8. Aesthetic and minimalist design
Every extra element competes with the important one. One primary action per screen.
**Fails as:** three buttons of equal weight, a dashboard where nothing stands out.

### 9. Help users recognize, diagnose and recover from errors
Plain language, the cause, and the next step — next to where the error happened.
**Fails as:** "Error 500", "Invalid field", a stack trace, a red border with no text.

### 10. Help and documentation
Findable when needed, task-oriented, short.
**Fails as:** a link to a 40-page manual as the answer to "what does this field mean".

## Using this in a review

Walk the design against all ten, marking each as ✅ / ⚠️ / ❌. A heuristic violation is reported like
a lint finding: **the rule, the location, the fix**. That is what makes it a decision rather than an
opinion — "this breaks heuristic 5, error prevention: the confirmation does not name what is being
deleted; use 'Delete invoice #123'" is actionable, "I don't like this dialog" is not.

Severity comes from the Design Constitution (`memory/design-constitution.md`), which encodes several
of these as [BLOCKING] rules. When they disagree, the constitution wins — it is the project's
decision; this list is the general theory behind it.
