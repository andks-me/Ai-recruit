# Ai-recruit

This project, **Ai-recruit**, is designed to streamline and enhance the recruitment process using artificial intelligence technologies. The goal is to automate various stages of recruitment, helping HR professionals to find the best candidates while reducing time and bias in hiring decisions.

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Introduction

**Ai-recruit** leverages advanced machine learning algorithms to evaluate candidates based on their skills, experiences, and potential fit with the company culture. By automating preliminary screenings and using data-driven insights, this tool reduces the burdens on HR teams and enhances decision-making.

## Features
- Intelligent matching of candidates and job descriptions
- Automated resume screening
- Predictive analytics for candidate success
- User-friendly interface for HR professionals

## Installation

To get started with **Ai-recruit**, clone this repository and install the necessary dependencies.

```bash
git clone https://github.com/andks-me/Ai-recruit.git
cd Ai-recruit
```

Install Elixir deps:
```bash
mix deps.get
```

## Usage

### Run API server

Set required env vars:

- `RECRUITMENT_SYSTEM_COOKIE_KEY_B64`: **base64 of 32 bytes** encryption key (AES-256-GCM) used to encrypt cookies at rest.
- `PORT` (optional): HTTP port, defaults to `4000`.

Example:

```bash
export RECRUITMENT_SYSTEM_COOKIE_KEY_B64="$(openssl rand -base64 32)"
export PORT=4000
mix run --no-halt
```

API is available at `http://localhost:4000`.

### Create/Configure LinkedIn agent session (li_at)

Endpoint: `POST /api/v1/agents/create`

Request body (example):

```json
{
  "agent_type": "linkedin",
  "user_id": "u_123",
  "linkedin_auth": {
    "li_at": "PASTE_LI_AT_HERE",
    "cookies": {
      "li_at": "PASTE_LI_AT_HERE",
      "JSESSIONID": "ajax:1234567890"
    },
    "user_agent": "Mozilla/5.0 ...",
    "proxy": "http://host:port"
  }
}
```

Response (example):

```json
{ "status": "OK", "agent_type": "linkedin", "user_id": "u_123" }
```

Notes:

- `li_at` is **validated as non-empty** and must look like a hex/base64-like token.
- Cookies are stored **encrypted at rest** (never log plaintext `li_at`).

### Revoke LinkedIn session (fix decrypt_failed / rotate key)

If you changed `RECRUITMENT_SYSTEM_COOKIE_KEY_B64` (new key) and the stored session can no longer be decrypted, revoke the stored session and create it again with the new key:

Endpoint: `DELETE /api/v1/agents/session`

```bash
curl -i -X DELETE http://localhost:4000/api/v1/agents/session \
  -H 'content-type: application/json' \
  -d '{"user_id":"u_123"}'
```

### How to obtain `li_at` safely

1. Log in to LinkedIn in your browser.
2. Open DevTools (F12) → **Application/Storage** → **Cookies**.
3. Select the `.linkedin.com` domain.
4. Copy the cookie named **`li_at`**.

Important:

- `li_at` is **short-lived** and may stop working after logout, cache clear, or LinkedIn security checks.
- Treat `li_at` like a password. Do **not** paste it into tickets/chats.

## Contributing

We welcome contributions from the community! Please follow these steps to contribute:
1. Fork the repository
2. Create a new branch (`git checkout -b feature-branch`)
3. Make your changes and commit them (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature-branch`)
5. Open a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Feel free to reach out if you have any questions or feedback!
