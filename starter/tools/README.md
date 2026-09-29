# tools/

Not synced into the game. Keep idempotent builder scripts here: Luau that an
agent runs through the Studio MCP `execute_luau` tool (Edit mode) to create
or update world geometry, UI, or lighting. Keeping them in git means the world
can be rebuilt or reviewed even though the place file itself is not committed.

Each script should delete or reuse what it created last time instead of
duplicating it, and print a one-line summary of what it changed.
