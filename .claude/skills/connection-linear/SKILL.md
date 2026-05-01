Use when the user asks to search, view, create, or update Linear issues, projects, or teams. Uses Linear's GraphQL API via `LINEAR_API_KEY`.

requires: [linear]

## Instructions

1. **Parse $ARGUMENTS** for the action and parameters. Supported actions:

### Issues
- **search**: Search issues by text query
- **get**: Get a single issue by UUID or identifier (e.g., `ENG-123`)
- **create**: Create an issue (requires `teamId`, plus `title`, optional `description`, `priority`, `assigneeId`, `labelIds`, `projectId`, `cycleId`)
- **update**: Update an issue (by id — update `title`, `description`, `stateId`, `priority`, `assigneeId`, etc.)
- **comment**: Add a comment to an issue

### Teams
- **teams list**: List all teams with their IDs

### Projects
- **projects list**: List projects (optionally filter by team)

### Cycles
- **cycles list**: List active cycles (optionally filter by team)

2. **API endpoint**: `https://api.linear.app/graphql`

3. **Authentication**: Use `LINEAR_API_KEY` environment variable:
   ```bash
   curl -s -X POST https://api.linear.app/graphql \
     -H "Content-Type: application/json" \
     -H "Authorization: $LINEAR_API_KEY" \
     -d '{"query": "..."}'
   ```

4. **Common GraphQL queries**:

   ### Search issues
   ```graphql
   query { issueSearch(query: "<text>", first: 20) { nodes { id identifier title state { name } assignee { name } priority } } }
   ```

   ### Get issue by identifier
   ```graphql
   query { issue(id: "<uuid>") { id identifier title description state { name } assignee { name } priority labels { nodes { name } } comments { nodes { body user { name } createdAt } } } }
   ```
   For identifiers like `ENG-123`, first search by identifier then fetch by UUID.

   ### Create issue
   ```graphql
   mutation { issueCreate(input: { teamId: "<teamId>", title: "<title>", description: "<desc>" }) { success issue { id identifier url } } }
   ```

   ### Update issue
   ```graphql
   mutation { issueUpdate(id: "<id>", input: { stateId: "<stateId>" }) { success issue { id identifier title state { name } } } }
   ```

   ### List teams
   ```graphql
   query { teams { nodes { id name key } } }
   ```

   ### List projects
   ```graphql
   query { projects(first: 50) { nodes { id name state } } }
   ```

   ### List active cycles
   ```graphql
   query { cycles(filter: { isActive: { eq: true } }) { nodes { id name number team { name } startsAt endsAt } } }
   ```

   ### Comment on issue
   ```graphql
   mutation { commentCreate(input: { issueId: "<issueId>", body: "<comment>" }) { success comment { id body } } }
   ```

5. **Format results** as readable markdown tables.

6. **If auth fails**: tell the user to set the `LINEAR_API_KEY` environment variable. Get a token from https://linear.app/settings/api.

Use $ARGUMENTS for the action and parameters.
