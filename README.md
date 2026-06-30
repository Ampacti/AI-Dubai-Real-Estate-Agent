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

---

## Screenshots

<img width="1375" height="896" alt="Screenshot (90)" src="https://github.com/user-attachments/assets/3d573f3b-1a48-4d15-8acf-37665d9ae115" />
<img width="1558" height="894" alt="Screenshot (89)" src="https://github.com/user-attachments/assets/d5828b3c-a82c-473d-85c1-5a58eb123812" />
<img width="1860" height="810" alt="Screenshot (88)" src="https://github.com/user-attachments/assets/b38a5a8c-8bc1-4a78-9a82-1868902c61fd" />


---

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
