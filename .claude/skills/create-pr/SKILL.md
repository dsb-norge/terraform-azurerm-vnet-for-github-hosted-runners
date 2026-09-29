---
name: create-pr
description: 'Create a pull request from the current feature branch with a descriptive title and detailed description.'
disable-model-invocation: true
user-invocable: true
---
<!--

  Auto-generated — do not edit manually.

-->
<!--

  Read by: Claude Code (as /skill-name slash command), VS Code Copilot (as /skill-name slash command).

-->
# Create a PR from changes on a branch

## First do this

- Verify we are on a feature branch and not on main or master. If not, inform user and stop.
- Check for unstaged changes. If there are any, inform the user and stop.
- Check for uncommitted changes. If there are any, inform the user and stop.
- Check for unpushed commits. If there are any, offer to push for them. If the user declines, inform them that they need to push before creating a PR and stop.

## Then do this

- Go through all changes on the branch to get a clear picture of what teh changes are about. This will help in writing a good PR description.
- Write a concise and descriptive PR title that accurately reflects the changes made in the branch. The title should be clear and informative, giving reviewers a good idea of what the PR is about at a glance. Make sure to not have a title longer than 70 characters as the GitHub UI will truncate it.
- Write a detailed PR description that provides context for the changes made in the branch. The description should explain the motivation behind the changes, the problem being solved, and any relevant background information. It should also include a summary of the changes made, any important details that reviewers should be aware of, and any instructions for reviewing the changes. Do not include instructions for testing, QA checklist or similar. The description should be well-organized and easy to read, using paragraphs and bullet points as needed to clearly convey the information.
- Create the PR using the GitHub CLI, ensuring that the correct base branch is selected (usually main). After creating the PR, output the PR summary and inform the user of the PR URL.
