# 🏡 AI Dubai Real Estate Agent

An AI-powered real estate assistant built with **n8n** that automates property inquiries from Telegram, collects lead information, recommends suitable properties, and stores qualified leads for follow-up.

---

## ✨ Features

-  AI-powered conversations
-  Telegram integration
-  Property recommendations
-  Automatic lead qualification
-  Context-aware conversations
-  Fully automated workflow

---

##  Tech Stack

- n8n
- Groq (this chat model can be changed)
- Telegram Bot API
- HTTP Requests
- JSON Workflows

---

## Workflow Overview

1. User starts a conversation in Telegram.
2. AI collects buyer preferences.
3. Property recommendations are generated.
4. Qualified lead information is extracted.
5. Lead is saved into simple memory.
6. Agent receives notification.


## Installation

1. Clone this repository.

```
git clone https://github.com/Ampacti/ai-real-estate-agent.git
```

2. Import the n8n workflow.

3. Configure:

- Telegram Bot Token and Chat ids
- Groq API Key
- property finer API key (reccomending xrapid key)

4. Activate the workflow.

---

## Future Improvements

- Voice message support
- Multi-language conversations
- Property image search
- Calendar booking
- WhatsApp support

---

## License

MIT
