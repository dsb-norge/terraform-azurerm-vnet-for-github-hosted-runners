<!--

  Auto-generated — do not edit manually.

-->
<!--

  Read by: VS Code Copilot only (as /prompt-name slash command).
  NOT read by: Claude Code, GitHub.com Coding Agent, or any other surface.

  NOTE: VS Code setting chat.promptFiles must point to the directory containing this file.

-->
<!--

  NOTE: make sure the vscode setting [chat.promptFiles](vscode://settings/chat.promptFiles) points to the directory of this file.

-->
# Commit local changes to a local branch

Before looking at the changes, ensure that a local non-main branch exists and is checked out. If not, create a new local branch from the main branch and switch to it.

Go through local changes, both staged and unstaged. Attempt to group the changes into logical commits. Use semantic commit message format for the commit subject. Commit message subject length threshold is 70 characters. If the commit message body is needed, it should be separated from the subject by a blank line. The body should not be wrapped. The body should be split into multiple paragraphs if needed, each separated by a blank line. The commit message should be concise and descriptive of the changes made. If there are multiple commits, ensure that each commit message accurately reflects the changes included in that commit.

After committing to a local branch, DO NOT push to remote.

As the final step, output a summary of the commits that were made.
