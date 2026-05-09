I provided LLM with the DDL sql script generated from DBeaver for the world database.

- Pretty strong reasoning model GPT-5.5 Extended Thinking – but instructions need to be clear and concise avoiding unnecessary details or complex language.

- Wrapped in **comments** the GPT generated content in tasks 1-4, provided my own versions of the queries.

- task8 and task9 were implemented with the help of GPT.

<br>
<br>

## Offside notes:
- Regarding the AdventureWorks database docker compose, it used to show error that image was upgraded but the database was not, thus container didn't run. **Switching** to 17.4 version of postgres image solved the issue.