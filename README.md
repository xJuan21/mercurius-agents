# Mercurius Agents

Configurable AI agents that make decisions inside InterSystems IRIS Interoperability
productions, built on IRIS AI Hub.

Agents are stored records, not generated classes. One runtime runs them all. Each agent has
its own instructions, permitted tools, private knowledge and memory. Its decision then
routes a real message through a production.

## What it does

A document arrives at a Business Service. The **Documenter** agent searches its private
knowledge and decides whether the document relates to, or contradicts, what it already
knows. A contradiction is recorded as an open finding and routed to review. Alerts follow
the same production and code, but reach the **Sentinel** agent, which has different
instructions and tools. **Forge** reviews code against the team's standards.

```text
File inbox or web UI -> DocumentIngress / AlertIngress / CodeIngress / ChatIngress (BS)
                   |
             AgentWorkflow (BP) -> AgentRunner (BO) -> AI Hub agent + permitted tools
                   |
          validated decision routes the message
                   |
      +------------+------------+
      v                         v
 ResultHandler (BO)        ReviewQueue (BO)
```

| Deterministic code | AI judgment |
|---|---|
| Saving documents, checking tool permissions, enforcing ownership, validating the decision against allowed values, routing | Choosing search terms, comparing notes, proposing a decision |

An invalid or failed reply never gets accepted: it goes to review.

## Requirements

- Docker with Compose
- The **AI Hub Community** image, build `2027.1.0AI.109.0`, from the
  [EAP portal](https://evaluation.intersystems.com/Eval/early-access/AIHub).
  It can't be pulled from a registry, and this repo never publishes it.
- An **OpenAI** API key. Variable: `OPENAI_API_KEY`. The default model is `gpt-4.1-mini`.

## Install

Load the image and give it the short tag used by the Dockerfile:

```bash
docker image load -i iris-community-2027.1.0AI.109.0-docker.tar.gz
docker tag docker.iscinternal.com/docker-intersystems/intersystems/iris-community:2027.1.0AI.109.0 iris-community:2027.1.0AI.109.0
```

Clone, add your key and start:

```bash
git clone https://github.com/xJuan21/mercurius-agents.git
cd mercurius-agents
cp .env.example .env      # then put your key in .env
docker compose up -d --build
```

The build compiles the code, seeds the sample agents and sets the production to start
with IRIS.

### Install with IPM

On an IRIS AI Hub instance, build `2027.1.0AI.109.0`:

```objectscript
zpm "install mercurius-agents"
```

This installs the backend: agents, production, API and sign-in. The web UI is built by Docker,
so use the Docker install above for the full app. IRIS needs `OPENAI_API_KEY` in its
environment.

## Verify

```bash
docker compose ps                                                          # shows (healthy)
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:52775/mercurius/   # 200
```

Backend checks, no LLM needed:

```bash
echo 'Do ##class(Mercurius.Test.Acceptance).Run() Halt' | docker compose exec -T iris iris session IRIS -U IRISAPP
```

This writes test records, and `demo/run.sh` resets them.

## Sign in

Open http://localhost:52775/mercurius/ and sign in with an IRIS account. On a fresh local
build, that's `_SYSTEM` with the image's default password. To add a user, create it in the
portal and give it the `MercuriusUser` role.

## Use it

| Page | What it does |
|---|---|
| Chat | Sends a message through the production and shows the agent's decision, tools and trace |
| Agents | Shows the agents. **Build an agent** creates a stored agent that runs immediately |
| Review | Lists open conflicts. A person resolves, reviews or dismisses each one |
| Memory, Knowledge | Show what the selected agent holds privately |
| History | Shows every run, including those from the file services |

To send the sample events through the file services instead:

```bash
./demo/run.sh
```

LLM judgment varies between runs. The Management Portal is at
http://localhost:52775/csp/sys/UtilHome.csp, and each decision links to its message trace.

## Add an agent

Use **Build an agent** in the UI: no new class is needed. The runtime adds the reply format
from the agent's decision values. To drive an agent from a file service too, add a Business
Service item and set its `AgentName` setting.

## Web UI

The UI is an Angular app in `web/`, built in a separate Docker stage. IRIS serves the output.

| Path | Purpose |
|---|---|
| `web/src/app/core` | Sign-in, API access and shared state |
| `web/src/app/layout` | The main layout |
| `web/src/app/shared` | Reusable components |
| `web/src/app/features` | One folder per page |

Sign-in uses the JWT support built into IRIS REST web applications. IRIS checks the password
and provides `/login`, `/refresh` and `/logout`. The access token stays in memory, and the
refresh token stays in `sessionStorage`, so it ends with the browser tab.

## Why not `EnsLib.AI.Agent.PassthroughOperation`?

IRIS ships an experimental operation and adapter for calling an agent from a production.
We tested them on build 109 and kept our own `AgentRunner` operation.

| | `EnsLib.AI.Agent.*` | `AgentRunner` |
|---|---|---|
| Agent configuration | Built once per production item, at startup | Loaded from a stored record on each message |
| Agents per item | One | Any |
| Per-agent tool identity | Not with settings alone: `AuthPolicy` is created with a bare `%New()` | Set by the runtime |
| A failed LLM call | Message error | Recorded result, routed to review |
| Message trace | Persistent `LLMResponse` with usage | Our own message classes |

Subclassing the adapter and using its `OnAfterAgentInit` hook does give per-agent tools,
so it's a possible later direction once the classes are no longer experimental.

## Security

- The runtime binds each tool to its agent, so the LLM never supplies the agent's identity.
- `Mercurius.Runtime.ToolPolicy` checks every tool against the agent's grants, and
  ungranted tools aren't shown to the LLM.
- `KnowledgeService` enforces ownership, so relationships can't cross agents.
- Every tool call is audited in `Mercurius.Model.AgentToolCall`.
- Agents get no SQL, filesystem or shell tools.
- The API requires a token, and users need the `MercuriusAccess` resource. `/mercurius/` serves only the built web files.
- Use HTTPS or a private network: passwords are sent at sign-in.

## Gotchas found on build 109

| Symptom | Cause | Fix |
|---|---|---|
| Container restarts with exit 134: `Unable to find/open file iris-main.log` | The repo is bind-mounted over the working directory, and the IRIS user can't write there | `working_dir: /home/irisowner` in `docker-compose.yml` |
| `<PRIVATE METHOD>` from `ToolManager.AddToolSetInstance()` | The method is private | Use `ToolManager.AddTool(instance)`, which keeps instance properties through `Chat()` |
| A tool hidden by `%CanList` isn't audited when called | The call fails as `ToolNotFound`, before `%CanExecute` and `%LogDenial` | Also check permissions in your own services |
| `No repositories are configured` from `zpm` in another namespace | `enable -community` alone doesn't map the repositories | Also run `zpm "enable -map -repos -globally"` in `%SYS` |
| A static web application returns 404 at its root | It has no default document | Serve `index.html` from a small dispatch class, as `Mercurius.API.Web` does |
| Every `%CSP.REST` route returns the same output | A method named `Page` overrides `%CSP.Page` | Use another method name |
| An API call fails on a `Role` column | `Role` is reserved in SQL | Quote it |

## Known limitations

- Knowledge search is basic text matching, so related notes can be missed.
- A conflict is an AI finding, not a verified fact.
- An LLM call that hangs has no timeout of its own.
- API keys are redacted from stored errors. Other sensitive text in an error is not.
- Chat shows decisions, not free conversation.
- Agents can be disabled but not deleted from the UI.
- AI Hub is pre-release software.
