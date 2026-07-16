<div align="center">

# SyferX AI Router

**One local OpenAI-compatible endpoint for many AI providers.**

Route Claude, OpenAI, Gemini, and other providers through one dashboard and API.

</div>

---

## Quick Start (Windows)

Use the GUI launcher:

```powershell
powershell -ExecutionPolicy Bypass -File .\GUI.ps1
```

Then run:

1. Install Requirements
2. Build
3. START
4. Open Dashboard

Enable `Start at Windows login` in the GUI if you want the server to start on boot.

## Manual Start

```bash
pnpm install
pnpm run build
pnpm run start
```

Open `http://localhost:20127`.

- Dashboard: `http://localhost:20127/dashboard`
- API endpoint: `http://localhost:20127/v1`
- Default login password: `123456`

## Use With OpenAI-Compatible Clients

Point your client at the local API:

```text
Base URL: http://localhost:20127/v1
API Key:  create one in Dashboard > Endpoint & Key
```

Works with tools that support OpenAI-compatible APIs, including Claude Code, OpenAI Codex, Cline, Cursor, and similar clients.

## Requirements

- Node.js 20+
- pnpm (`npm i -g pnpm`)
- Windows for the GUI launcher; server can run anywhere Next.js supports

## Data Location

Keys and settings are stored locally:

```text
Windows:      %APPDATA%\9router\db\data.sqlite
macOS/Linux:  ~/.9router/db/data.sqlite
```

## Scripts

```bash
pnpm run dev        # start development server on port 20127
pnpm run build      # build production app
pnpm run start      # start production server on port 20127
pnpm run lint       # run ESLint
```

## License

MIT
