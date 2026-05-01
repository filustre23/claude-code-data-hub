Use when the user asks to view, create, comment on, or search GitHub repos, issues, PRs, or workflow runs. Uses the `gh` CLI.

requires: [github]

## Instructions

1. **Parse $ARGUMENTS** for the action and parameters. Supported actions:

### Repos
- **repos list**: `gh repo list [owner] --limit 30`
- **repos view**: `gh repo view [owner/repo]`
- **repos clone**: `gh repo clone <owner/repo>`

### Pull Requests
- **pr list**: `gh pr list -R <owner/repo> [--state open|closed|merged]`
- **pr view**: `gh pr view <number> -R <owner/repo>`
- **pr create**: `gh pr create -R <owner/repo> --title "..." --body "..."`
- **pr review**: `gh pr review <number> -R <owner/repo> --approve|--comment|--request-changes`
- **pr merge**: `gh pr merge <number> -R <owner/repo> [--merge|--squash|--rebase]`
- **pr comment**: `gh pr comment <number> -R <owner/repo> --body "..."`
- **pr checks**: `gh pr checks <number> -R <owner/repo>`
- **pr diff**: `gh pr diff <number> -R <owner/repo>`

### Actions / Workflows
- **runs list**: `gh run list -R <owner/repo> --limit 10`
- **run view**: `gh run view <run_id> -R <owner/repo>`
- **run log**: `gh run view <run_id> -R <owner/repo> --log-failed`
- **run rerun**: `gh run rerun <run_id> -R <owner/repo>`
- **workflows list**: `gh workflow list -R <owner/repo>`
- **workflow trigger**: `gh workflow run <workflow> -R <owner/repo>`

### Issues
- **issue list**: `gh issue list -R <owner/repo> [--state open|closed]`
- **issue create**: `gh issue create -R <owner/repo> --title "..." --body "..."`
- **issue view**: `gh issue view <number> -R <owner/repo>`
- **issue comment**: `gh issue comment <number> -R <owner/repo> --body "..."`
- **issue close**: `gh issue close <number> -R <owner/repo>`

### API (escape hatch)
- **api**: `gh api <endpoint>` for any GitHub REST/GraphQL API call not covered above

2. **Repo context**: Use `-R <owner/repo>` to target a specific repository. Detect from git remote if not specified:
   ```bash
   gh repo view --json nameWithOwner -q .nameWithOwner
   ```

3. **Format results** as readable markdown.

4. **If auth fails**: tell the user to run `gh auth login`.

Use $ARGUMENTS for the action and parameters.
