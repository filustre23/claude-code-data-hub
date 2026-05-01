Use when the user asks to inspect Snowflake databases, list schemas, check warehouse usage, or run admin operations. For ad-hoc SELECT queries, prefer `/data-run-query`.

Query, explore, and manage Snowflake databases using `snowsql` or Python `snowflake-connector-python`.

requires: [snowflake]

## Instructions

1. **Parse $ARGUMENTS** for the action and parameters. Supported actions:
   - **query** (default): Run a SQL query
   - **list-databases**: List available databases
   - **list-schemas**: List schemas in a database
   - **list-tables**: List tables in a schema
   - **schema**: Inspect a table's schema/columns

2. **Detect credentials** from project config (in order of priority):
   - dbt `profiles.yml` (look for `type: snowflake`) — extract `account`, `user`, `password`/`authenticator`, `role`, `warehouse`, `database`, `schema`
   - Environment variables: `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`

3. **Execute the action**:

   ### Query
   Using `snowsql`:
   ```bash
   snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -r $SNOWFLAKE_ROLE -w $SNOWFLAKE_WAREHOUSE -d $SNOWFLAKE_DATABASE -q "SELECT ..."
   ```
   Or using Python:
   ```bash
   uv run python -c "
   import snowflake.connector, os, json
   conn = snowflake.connector.connect(
       account=os.environ['SNOWFLAKE_ACCOUNT'],
       user=os.environ['SNOWFLAKE_USER'],
       password=os.environ['SNOWFLAKE_PASSWORD'],
       role=os.environ.get('SNOWFLAKE_ROLE'),
       warehouse=os.environ.get('SNOWFLAKE_WAREHOUSE'),
       database=os.environ.get('SNOWFLAKE_DATABASE')
   )
   cur = conn.cursor()
   cur.execute('''<SQL>''')
   print(json.dumps(cur.fetchall()))
   "
   ```
   - Add a default `LIMIT 100` unless the user specifies otherwise

   ### List databases
   ```sql
   SHOW DATABASES;
   ```

   ### List schemas
   ```sql
   SHOW SCHEMAS IN DATABASE <database>;
   ```

   ### List tables
   ```sql
   SHOW TABLES IN SCHEMA <database>.<schema>;
   ```

   ### Schema
   ```sql
   DESCRIBE TABLE <database>.<schema>.<table>;
   ```

4. **Format results** as readable markdown tables.

5. **If auth fails**: tell the user to set Snowflake environment variables or configure `profiles.yml`:
   ```bash
   export SNOWFLAKE_ACCOUNT="your_account"
   export SNOWFLAKE_USER="your_user"
   export SNOWFLAKE_PASSWORD="your_password"
   export SNOWFLAKE_ROLE="your_role"
   export SNOWFLAKE_WAREHOUSE="your_warehouse"
   export SNOWFLAKE_DATABASE="your_database"
   ```

Use $ARGUMENTS for the action and parameters.
