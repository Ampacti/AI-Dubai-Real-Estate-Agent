{
  "name": "Telegram Real Estate AI Agent",
  "nodes": [
    {
      "parameters": {
        "conditions": {
          "options": {
            "caseSensitive": true,
            "leftValue": "",
            "typeValidation": "strict",
            "version": 3
          },
          "conditions": [
            {
              "leftValue": "={{ $json.output }}",
              "rightValue": "SEARCH_READY",
              "operator": {
                "type": "string",
                "operation": "contains"
              },
              "id": "cb834c6d-b171-45fa-9681-325404f781ef"
            }
          ],
          "combinator": "or"
        },
        "options": {}
      },
      "id": "575e1b36-9a06-4eb1-b692-0b8822ded7b6",
      "name": "Search Ready?",
      "type": "n8n-nodes-base.if",
      "typeVersion": 2.3,
      "position": [
        -992,
        192
      ]
    },
    {
      "parameters": {
        "jsCode": "// Extract property search parameters from AI conversation - FLEXIBLE SEARCH\nconst chatHistory = $input.all();\nconst conversationText = chatHistory.map(item => item.json.output || item.json.text || \"\").join(\" \");\n\n// Initialize parameters - ONLY set what user explicitly mentioned\nconst params = {\n  purpose: \"for-sale\",\n  sort: \"city-level-score\",\n  hitsPerPage: \"10\"\n};\n\n// Detect purpose (buy/rent)\nif (/\\b(rent|rental|lease)\\b/i.test(conversationText)) {\n  params.purpose = \"for-rent\";\n}\n\n// Detect property type - ONLY if explicitly mentioned\nif (/\\b(apartment|flat)\\b/i.test(conversationText)) {\n  params.categoryExternalID = \"4\";\n} else if (/\\bvilla\\b/i.test(conversationText)) {\n  params.categoryExternalID = \"3\";\n} else if (/\\btownhouse\\b/i.test(conversationText)) {\n  params.categoryExternalID = \"16\";\n} else if (/\\bpenthouse\\b/i.test(conversationText)) {\n  params.categoryExternalID = \"18\";\n}\n\n// Extract budget - WIDEN the range by 30% for flexibility\nconst priceMatches = conversationText.match(/\\b(\\d+(?:,\\d{3})*(?:\\.\\d+)?)[\\s]*(k|thousand|million|m)?\\b/gi);\nif (priceMatches && priceMatches.length >= 2) {\n  const prices = priceMatches.map(p => {\n    let num = parseFloat(p.replace(/,/g, \"\"));\n    if (/k|thousand/i.test(p)) num *= 1000;\n    if (/m|million/i.test(p)) num *= 1000000;\n    return num;\n  });\n  const minBudget = Math.min(...prices);\n  const maxBudget = Math.max(...prices);\n  \n  // Expand range by 30% to show more options\n  params.minPrice = Math.floor(minBudget * 0.7).toString();\n  params.maxPrice = Math.ceil(maxBudget * 1.3).toString();\n} else if (priceMatches && priceMatches.length === 1) {\n  // Single price mentioned - create range around it\n  let num = parseFloat(priceMatches[0].replace(/,/g, \"\"));\n  if (/k|thousand/i.test(priceMatches[0])) num *= 1000;\n  if (/m|million/i.test(priceMatches[0])) num *= 1000000;\n  \n  params.minPrice = Math.floor(num * 0.7).toString();\n  params.maxPrice = Math.ceil(num * 1.3).toString();\n}\n\n// Extract bedrooms - allow ±1 bedroom flexibility\nconst bedroomMatch = conversationText.match(/\\b(\\d+)[\\s]*(bed|bedroom)/i);\nif (bedroomMatch) {\n  const beds = parseInt(bedroomMatch[1]);\n  params.roomsMin = Math.max(1, beds - 1).toString();\n  params.roomsMax = (beds + 1).toString();\n}\n\n// Skip furnished status for more results - too restrictive\n\n// Detect popular Dubai areas - but don't restrict if not mentioned\nconst areaMap = {\n  \"marina\": \"dubai-marina\",\n  \"downtown\": \"downtown-dubai\",\n  \"jbr\": \"jumeirah-beach-residence-jbr\",\n  \"palm\": \"palm-jumeirah\",\n  \"business bay\": \"business-bay\",\n  \"jlt\": \"jumeirah-lake-towers-jlt\"\n};\n\nfor (const [key, value] of Object.entries(areaMap)) {\n  if (new RegExp(\"\\\\b\" + key + \"\\\\b\", \"i\").test(conversationText)) {\n    params.locationExternalIDs = value;\n    break;\n  }\n}\n\nreturn [{ json: params }];"
      },
      "id": "b09c3e25-3576-4cdd-9cbe-a3a46bc2e28a",
      "name": "Extract Search Parameters",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        -704,
        144
      ]
    },
    {
      "parameters": {
        "jsCode": "// Format property listings for Telegram display\nconst data = $input.first().json;\nconst properties = data.hits || [];\n\nif (properties.length === 0) {\n  return [{\n    json: {\n      message: \"I couldn't find any properties matching your criteria. Would you like to adjust your budget or preferred area?\",\n      hasProperties: false\n    }\n  }];\n}\n\nlet message = \"🏠 Here are the top properties I found for you:\\n\\n\";\n\nconst formattedProperties = properties.slice(0, 8).map((prop, index) => {\n  const title = prop.title || \"Property\";\n  const price = prop.price ? `AED ${prop.price.toLocaleString()}` : \"Price on request\";\n  const location = prop.location?.[0]?.name || \"Dubai\";\n  const beds = prop.rooms || \"N/A\";\n  const baths = prop.baths || \"N/A\";\n  const area = prop.area ? `${prop.area} sqft` : \"N/A\";\n  const photo = prop.coverPhoto?.url || \"\";\n  const link = `https://www.bayut.com/property/details-${prop.externalID}.html`;\n\n  message += `${index + 1}. ${title}\\n`;\n  message += `📍 ${location}\\n`;\n  message += `💰 ${price}\\n`;\n  message += `🛏 ${beds} Beds | 🚿 ${baths} Baths | 📐 ${area}\\n`;\n  message += `🔗 ${link}\\n\\n`;\n\n  return {\n    index: index + 1,\n    title,\n    price,\n    location,\n    beds,\n    baths,\n    area,\n    photo,\n    link,\n    propertyId: prop.id,\n    externalID: prop.externalID,\n    fullData: prop\n  };\n});\n\nmessage += \"Which property interests you? Reply with the number, or let me know if you'd like to see more options.\";\n\nreturn [{\n  json: {\n    message,\n    hasProperties: true,\n    properties: formattedProperties,\n    firstPhoto: formattedProperties[0]?.photo || \"\"\n  }\n}];"
      },
      "id": "07e909f6-b31c-4a59-9a5c-59499e536a44",
      "name": "Format Properties for Telegram",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        -176,
        240
      ]
    },
    {
      "parameters": {
        "chatId": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
        "text": "={{ $json.message }}",
        "additionalFields": {
          "appendAttribution": false,
          "disable_web_page_preview": false,
          "parse_mode": "HTML"
        }
      },
      "id": "8e07c3a7-cf73-4e2e-86cb-840f1d9c19e9",
      "name": "Send Properties to User",
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [
        48,
        240
      ],
      "webhookId": "7de7de51-f765-47ab-8677-af2f9be967df"
    },
    {
      "parameters": {
        "conditions": {
          "options": {
            "caseSensitive": true,
            "leftValue": "",
            "typeValidation": "strict",
            "version": 3
          },
          "conditions": [
            {
              "leftValue": "={{ $json.output }}",
              "rightValue": "LEAD_READY",
              "operator": {
                "type": "string",
                "operation": "contains"
              },
              "id": "8e06e8c2-a1ae-4db1-abf4-c9ab8af6c4f7"
            }
          ],
          "combinator": "or"
        },
        "options": {}
      },
      "id": "8b57781f-4c7a-4a00-a1aa-d3573934b447",
      "name": "Lead Ready?",
      "type": "n8n-nodes-base.if",
      "typeVersion": 2.3,
      "position": [
        -1376,
        336
      ]
    },
    {
      "parameters": {
        "assignments": {
          "assignments": [
            {
              "id": "1",
              "name": "leadMessage",
              "type": "string",
              "value": "=🔥 NEW QUALIFIED LEAD\n\n👤 Name: {{ $json.customerName }}\n📱 Phone/WhatsApp: {{ $json.phoneNumber }}\n📧 Email: {{ $json.email }}\n🌍 Country: {{ $json.country }}\n🕐 Best time to call: {{ $json.contactTime }}\n\n🏠 PROPERTY INTEREST\n• Looking to: {{ $json.lookingTo }}\n• Type: {{ $json.propertyType }}\n• Budget: AED {{ $json.budget }}\n• Areas: {{ $json.areas }}\n• Ready or off-plan: {{ $json.readyOrOffplan }}\n• Timeline: {{ $json.timeline }}\n\n⚡ ACTION REQUIRED: Contact this lead ASAP"
            }
          ]
        },
        "options": {}
      },
      "id": "fd5cbac9-2ea5-415f-b9e3-658680b3c8e9",
      "name": "Prepare Lead Notification",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.4,
      "position": [
        -688,
        560
      ]
    },
    {
      "parameters": {
        "chatId": "-1004244474704",
        "text": "={{ $json.leadMessage }}",
        "additionalFields": {
          "appendAttribution": false,
          "disable_notification": false
        }
      },
      "id": "bb83d7ee-961b-4624-a5bb-8446c7399521",
      "name": "Notify Real Estate Team",
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [
        -496,
        560
      ],
      "webhookId": "2cb32590-e641-4e7c-a71f-47088f6f2427"
    },
    {
      "parameters": {
        "chatId": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
        "text": "✅ Perfect! Your information has been received.\n\nOur Dubai real estate specialist will contact you shortly at your preferred time.\n\nThank you for using Dubai Property Finder! 🏠",
        "additionalFields": {
          "appendAttribution": false,
          "parse_mode": "HTML"
        }
      },
      "id": "1d6169b0-df86-4792-8d22-52b7957a7684",
      "name": "Confirm to Customer",
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [
        -304,
        560
      ],
      "webhookId": "69a72e2d-a9ae-491e-8042-e5003615f6eb"
    },
    {
      "parameters": {
        "chatId": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
        "text": "={{ $json.output }}",
        "additionalFields": {
          "appendAttribution": false,
          "parse_mode": "HTML"
        }
      },
      "id": "15472b12-1590-40f0-bc28-ce44e6d66740",
      "name": "Send AI Response",
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [
        -736,
        320
      ],
      "webhookId": "2f879900-0c78-4d97-b0c0-1142e4604f0b"
    },
    {
      "parameters": {
        "updates": [
          "message"
        ],
        "additionalFields": {}
      },
      "type": "n8n-nodes-base.telegramTrigger",
      "typeVersion": 1.2,
      "position": [
        -1824,
        336
      ],
      "id": "1a4a501b-ed1f-4fd5-af9d-965583e31c23",
      "name": "Telegram Trigger",
      "webhookId": "48325991-571e-4ccc-9f5b-54283a2e446c"
    },
    {
      "parameters": {
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth",
        "sendQuery": true,
        "queryParameters": {
          "parameters": [
            {
              "name": "locationExternalIDs",
              "value": "={{ $json.locationExternalIDs }}"
            },
            {
              "name": "purpose",
              "value": "={{ $json.purpose }}"
            },
            {
              "name": "categoryExternalID",
              "value": "={{ $json.categoryExternalID }}"
            },
            {
              "name": "minPrice",
              "value": "={{ $json.minPrice }}"
            },
            {
              "name": "maxPrice",
              "value": "={{ $json.maxPrice }}"
            },
            {
              "name": "roomsMin",
              "value": "={{ $json.roomsMin }}"
            },
            {
              "name": "roomsMax",
              "value": "={{ $json.roomsMax }}"
            },
            {
              "name": "sort",
              "value": "={{ $json.sort }}"
            },
            {
              "name": "hitsPerPage",
              "value": "={{ $json.hitsPerPage }}"
            }
          ]
        },
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {
              "name": "x-rapidapi-host"
            }
          ]
        },
        "options": {}
      },
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.3,
      "position": [
        -512,
        144
      ],
      "id": "06c0123d-f778-47da-bcd9-1d10596c5c6d",
      "name": "HTTP Request"
    },
    {
      "parameters": {
        "promptType": "define",
        "text": "={{ $('Telegram Trigger').item.json.message.text }}",
        "options": {
          "systemMessage": "You are Mr. Khalid, a luxury Dubai real estate consultant at Prime Properties Dubai.\n\nGREETING (first message only):\n\"Marhaba! 👋مرحبًا 🌟 I'm Mr. Khalid, your personal real estate advisor in Dubai. Whether you're looking for your dream home or a smart investment, I'm here to make it happen! 🏙️ What kind of property are you looking for?\"\n\nPERSONALITY:\n- Warm, confident, and human — like a trusted advisor, not a bot\n- Use friendly emojis naturally 🏠✨🌴💎 (don't overdo it)\nLANGUAGE RULE:\n- ALWAYS detect the language the user writes in and respond in that SAME language\n- Match their language exactly — if they write in Farsi, reply in Farsi; if English, reply in English; if Arabic, reply in Arabic; if Russian, French, Hindi, Urdu, etc. — match accordingly\n- NEVER mix languages in one reply (no Arabic+English combined unless the user mixed them first)\n- If the user switches language mid-conversation, switch with them immediately\n- Keep the same warm tone, emojis, and structure regardless of language\n- For currency conversions, school names, and area names — keep proper nouns (like \"Dubai Marina\", \"GEMS Wellington Academy\") in their original form even when replying in another language\n- Keep replies SHORT (2-3 sentences max)\n- Ask ONE question at a time\n- Take a moment to think before responding — give thoughtful, considered answers\n- Never rush — quality over speed\n\nTHINKING RULES (important):\n- Before every reply, internally review: what do I know so far? what's the best next step?\n- Never send a response until you've considered at least 2-3 property alternatives\n- If search returns nothing, IMMEDIATELY think of the closest alternative before replying\n\nCONVERSATION FLOW:\nPhase 1 — DISCOVER:\n- Get property type AND/OR area AND/OR budget AND/OR bedrooms\n- Even ONE piece of info is enough\n- Once you have anything useful, output exactly: SEARCH_READY\n\nPhase 2 — SHOW PROPERTIES:\n- ALWAYS present options enthusiastically — alternatives are opportunities, not failures\n- Never say \"I couldn't find\", \"no results\", \"not available\", \"unfortunately\"\n- If exact match isn't available: \"Great news! I found some fantastic options nearby — and honestly, a couple of these might surprise you! 🌟\"\n- Pivot naturally: different area, slightly higher/lower budget, different bedroom count\n- Frame upgrades positively: \"For just a bit more, you get [X] — which my clients absolutely love 💎\"\n- After showing properties, ask: \"Would you like me to arrange a callback with one of our senior agents? 🤝\"\n\nPhase 3 — QUALIFY THE LEAD (one at a time, naturally):\n- Buy or rent?\n- Ready to move in or off-plan?\n- Timeline to buy/move?\n- Budget (if not given)\n- Then collect contact info one field at a time:\n  1. Full name\n  2. Phone / WhatsApp number\n  3. Email (optional)\n  4. Country of residence\n  5. Best time to call\n- Once all collected, output exactly: LEAD_READY\nWhen a customer becomes a qualified lead and confirms interest in a property, collect and extract the following information whenever available:\n\n* Full Name\n* Phone Number / WhatsApp\n* Email Address\n* Country\n* Best Time To Call\n* Looking To (Buy or Rent)\n* Property Type\n* Budget\n* Preferred Areas\n* Ready Property or Off-Plan\n* Purchase Timeline\n\nSTRICT RULES — NEVER BREAK:\n- NEVER say \"I couldn't find\", \"no results\", \"unfortunately\", \"not available\"\n- ALWAYS have an enthusiastic alternative ready\n- NEVER reply twice in one turn\n- NEVER ask more than one question at a time\n- NEVER ask for contact info before showing properties\n- NEVER use robotic openers like \"Certainly!\" \"Of course!\" \"Absolutely!\"\n- NEVER add any footer, signature, or automated tag\n- Always be solution-focused, positive, and energetic 🌟\nVIEWING APPOINTMENTS:\n- When user wants to schedule a viewing, ask for preferred date and time\n- ALWAYS check calendar availability BEFORE confirming any appointment\n- If time slot is unavailable, suggest alternative times\n- Only create calendar event after confirming availability\n- Include all customer details in the appointment\n\nCURRENCY CONVERSION RULE (updated):\n- For AED ↔ Iranian Toman/Rial conversions, search specifically: \"tgju.org قیمت درهم امارات\" or \"site:tgju.org AED price today\"\n- Use the rate shown on tgju.org as your source of truth (note: tgju often shows Rial — divide by 10 to get Toman)\n- SANITY CHECK (critical): A Dubai property worth millions of AED must ALWAYS convert to a LARGER number in Toman, never smaller. If your result looks smaller than the original AED figure, you made a math error — the correct formula is: AED price × exchange rate = Toman price (multiply, not divide)\n- Show your work briefly so the user can verify: \"(X AED × today's rate from tgju.org of Y Toman/AED ≈ Z Toman)\"\n- Always state the source and that it's today's rate: \"Based on tgju.org's rate today (1 AED ≈ Y Toman)...\"\n- For other currencies (USD, EUR, GBP, etc.), use general web search for current rates with the same sanity-check logic\n\nCONTACT INFO COLLECTION (exact script — follow this flow precisely):\n\nStep 1: \"What's your full name? 😊\"\n→ Wait for answer\n\nStep 2: \"Great, [name]! Which country are you in? 🌍\"\n→ Wait for answer (use their actual name from Step 1)\n\nStep 3: \"Okay, what's your phone/WhatsApp number? 📱\"\n→ Wait for answer\n\nStep 4: \"Good, what day and time works best for a call? 🕐\"\n→ Wait for answer\n\nStep 5 (optional, only if not skipped): \"And your email, if you'd like to receive listings directly? 📧\"\n→ Wait for answer or \"skip\"\nAfter all information has been collected, output EXACTLY in this format:\n\n[LEAD_READY]\n\nName: [full name]\nPhone Number: [phone number]\nCountry: [country]\nEmail: [email or Not provided]\nBest Time to Call: [time]\n\nLooking To: [Buy or Rent]\nProperty Type: [property type]\nBudget: [budget]\nPreferred Areas: [areas]\nReady or Off-Plan: [answer]\nTimeline: [timeline]\n\n[/LEAD_READY]\n\nDo not add any extra text before or after this block.\n\n\nRULES FOR THIS FLOW:\n- Always use the client's actual name (from Step 1) in Steps 2-4 acknowledgments — never generic phrases\n- Acknowledge each answer briefly and warmly before the next question (e.g. \"Great, [name]!\", \"Perfect!\", \"Got it!\")\n- Never skip ahead or combine steps\n- If email is skipped, mark it as \"Not provided\" in the lead summary\n- This sequence only starts AFTER property discussion is complete and the client has agreed to be contacted\n\nINFORMATION ACCURACY RULE:\n- Being positive does NOT mean inventing or exaggerating facts — accuracy builds trust and closes deals\n- For project/market info, search these sources:\n  - bayut.com (listings + market research/insights)\n  - propertyfinder.ae (listings + Property Finder Trends)\n  - Official developer sites for off-plan details: emaar.com, damacproperties.com, sobharealty.com, nakheel.com, dubaiproperties.ae\n  - dubailand.gov.ae and dubaipulse.gov.ae for official transaction data, DLD fees, regulations\n  - gulfnews.com/business/property and khaleejtimes.com for market news\n- If you're not 100% sure about a specific project's handover date, exact payment plan, or unit availability, say so honestly but stay positive: \"I'd love to confirm the very latest details with our team so you get 100% accurate info — let me connect you with an agent for that specific project 🤝\"\n- NEVER invent specific numbers (prices, percentages, dates) you haven't verified through search — general market trends and typical ranges are fine, but project-specific figures must come from real sources\n- Note: Bayut/Property Finder show \"asking prices\" — actual closing prices (from DLD data) are often 5-15% lower. Mention this if relevant to set realistic expectations\n\nCURRENCY CONVERSION RULE (AED to Iranian Toman/Rial):\n- Use this baseline rate: 1 AED ≈ 44,000 Toman (≈ 440,000 Rial)\n- To convert: AED price × 44,000 = price in Toman (or × 440,000 for Rial)\n- Example: An apartment priced at AED 1,500,000 ≈ 1,500,000 × 44,000 = 66,000,000,000 Toman (66 billion Toman)\n- Always double-check your multiplication — Dubai property prices in Toman will be very large numbers (billions), this is normal and correct\n- When stating the converted price, mention it's an approximate estimate: \"That's roughly 66 billion Toman at current rates — I'd recommend confirming the exact figure with our team since exchange rates shift daily 💱\"\n- For other currencies (USD, EUR, GBP, etc.), use general web search for current approximate rates with the same multiplication logic",
          "maxIterations": 10
        }
      },
      "type": "@n8n/n8n-nodes-langchain.agent",
      "typeVersion": 3,
      "position": [
        -1664,
        336
      ],
      "id": "fee85f80-d1c8-425e-bd9a-e9ab4854d152",
      "name": "Dubai Real Estate AI Agent"
    },
    {
      "parameters": {
        "sessionIdType": "customKey",
        "sessionKey": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
        "contextWindowLength": 10
      },
      "type": "@n8n/n8n-nodes-langchain.memoryBufferWindow",
      "typeVersion": 1.3,
      "position": [
        -1408,
        576
      ],
      "id": "a4f5d768-05fb-4f7a-a137-dbb79330feec",
      "name": "Simple Memory"
    },
    {
      "parameters": {
        "assignments": {
          "assignments": [
            {
              "id": "0cf92493-2e13-4e90-91c6-519705f301d9",
              "name": "text",
              "value": "NO_RESULTS_FOUND: I searched but couldn't find properties matching those exact criteria. Please suggest alternatives like adjusting budget, nearby areas, or different property types.",
              "type": "string"
            }
          ]
        },
        "options": {}
      },
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.4,
      "position": [
        -192,
        80
      ],
      "id": "26e4c7c7-d3eb-47e8-9752-3cbf2f3f881b",
      "name": "Edit Fields"
    },
    {
      "parameters": {
        "conditions": {
          "options": {
            "caseSensitive": true,
            "leftValue": "",
            "typeValidation": "strict",
            "version": 3
          },
          "conditions": [
            {
              "id": "cdfec715-b749-4dca-8f25-76462bc13257",
              "leftValue": "={{ $json.hits }}",
              "rightValue": "",
              "operator": {
                "type": "array",
                "operation": "notEmpty",
                "singleValue": true
              }
            }
          ],
          "combinator": "and"
        },
        "options": {}
      },
      "type": "n8n-nodes-base.if",
      "typeVersion": 2.3,
      "position": [
        -352,
        144
      ],
      "id": "d8cce347-ad6e-4295-a687-ec97ba8e5bea",
      "name": "If"
    },
    {
      "parameters": {
        "promptType": "define",
        "text": "={{ $json.text }}",
        "options": {
          "systemMessage": "You are Mr. Khalid, a luxury Dubai real estate consultant at Prime Properties Dubai.\n\nGREETING (first message only):\n\"Marhaba! 🌟 I'm Mr. Khalid, your personal real estate advisor in Dubai. Whether you're looking for your dream home or a smart investment, I'm here to make it happen! 🏙️ What kind of property are you looking for?\"\n\nPERSONALITY:\n- Warm, confident, and human — like a trusted advisor, not a bot\n- Use friendly emojis naturally 🏠✨🌴💎 (don't overdo it)\n- Keep replies SHORT (2-3 sentences max)\n- Ask ONE question at a time\n- Take a moment to think before responding — give thoughtful, considered answers\n- Never rush — quality over speed\n\nTHINKING RULES (important):\n- Before every reply, internally review: what do I know so far? what's the best next step?\n- Never send a response until you've considered at least 2-3 property alternatives\n- If search returns nothing, IMMEDIATELY think of the closest alternative before replying\n\nCONVERSATION FLOW:\nPhase 1 — DISCOVER:\n- Get property type AND/OR area AND/OR budget AND/OR bedrooms\n- Even ONE piece of info is enough\n- Once you have anything useful, output exactly: SEARCH_READY\n\nPhase 2 — SHOW PROPERTIES:\n- ALWAYS present options enthusiastically — alternatives are opportunities, not failures\n- Never say \"I couldn't find\", \"no results\", \"not available\", \"unfortunately\"\n- If exact match isn't available: \"Great news! I found some fantastic options nearby — and honestly, a couple of these might surprise you! 🌟\"\n- Pivot naturally: different area, slightly higher/lower budget, different bedroom count\n- Frame upgrades positively: \"For just a bit more, you get [X] — which my clients absolutely love 💎\"\n- After showing properties, ask: \"Would you like me to arrange a callback with one of our senior agents? 🤝\"\n\nPhase 3 — QUALIFY THE LEAD (one at a time, naturally):\n- Buy or rent?\n- Ready to move in or off-plan?\n- Timeline to buy/move?\n- Budget (if not given)\n- Then collect contact info one field at a time:\n  1. Full name\n  2. Phone / WhatsApp number\n  3. Email (optional)\n  4. Country of residence\n  5. Best time to call\n- Once all collected, output exactly: LEAD_READY\n\nLEAD MESSAGE FORMAT:\n🔥 NEW QUALIFIED LEAD\n\n👤 Name: [name]\n📱 Phone/WhatsApp: [phone]\n📧 Email: [email or 'Not provided']\n🌍 Country: [country]\n🕐 Best time to call: [time]\n\n🏠 PROPERTY INTEREST\n• Looking to: [Buy / Rent]\n• Type: [apartment/villa/etc]\n• Budget: AED [range]\n• Areas: [areas]\n• Ready or off-plan: [answer]\n• Timeline: [timeline]\n\n⚡ ACTION REQUIRED: Contact this lead ASAP\n\nSTRICT RULES — NEVER BREAK:\n- NEVER say \"I couldn't find\", \"no results\", \"unfortunately\", \"not available\"\n- ALWAYS have an enthusiastic alternative ready\n- NEVER reply twice in one turn\n- NEVER ask more than one question at a time\n- NEVER ask for contact info before showing properties\n- NEVER use robotic openers like \"Certainly!\" \"Of course!\" \"Absolutely!\"\n- NEVER add any footer, signature, or automated tag\n- Always be solution-focused, positive, and energetic 🌟",
          "maxIterations": 10
        }
      },
      "type": "@n8n/n8n-nodes-langchain.agent",
      "typeVersion": 3,
      "position": [
        0,
        0
      ],
      "id": "78505bc2-fb37-4fc9-a065-561e924018e9",
      "name": "AI Agent"
    },
    {
      "parameters": {
        "chatId": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
        "text": "={{ $json.output }}",
        "additionalFields": {
          "appendAttribution": false,
          "parse_mode": "HTML"
        }
      },
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [
        304,
        128
      ],
      "id": "dc3642d1-9c38-4231-891c-b5924e858aff",
      "name": "Send a text message",
      "webhookId": "df55a4e7-f23d-4401-8a82-7737fdc3bd7d"
    },
    {
      "parameters": {
        "toolDescription": "Search the web using DuckDuckGo. Use this tool when users ask for current information, currency conversions, general knowledge, regulations, or information outside the real estate domain. Pass the user's question as the query.",
        "url": "=https://www.tgju.org/profile/price_aed",
        "sendQuery": true,
        "queryParameters": {
          "parameters": [
            {
              "name": "q",
              "value": "={{ $fromAI('query') }}"
            },
            {
              "name": "format",
              "value": "json"
            },
            {
              "name": "no_html",
              "value": "1"
            },
            {
              "name": "skip_disambig",
              "value": "1"
            }
          ]
        },
        "options": {},
        "optimizeResponse": true,
        "responseType": "html",
        "cssSelector": ".result__body",
        "onlyContent": true,
        "elementsToOmit": "script, style, noscript, iframe",
        "truncateResponse": true
      },
      "type": "n8n-nodes-base.httpRequestTool",
      "typeVersion": 4.3,
      "position": [
        -1568,
        576
      ],
      "id": "2f59aa18-afa3-4dc2-ba14-5c5e8f982d32",
      "name": "HTTP Request1"
    },
    {
      "parameters": {
        "jsCode": "const text = $input.first().json.output || \"\";\n\nfunction extract(field) {\n  const regex = new RegExp(field + \":\\\\s*(.*)\", \"i\");\n  const match = text.match(regex);\n  return match ? match[1].trim() : \"Not provided\";\n}\n\nreturn [{\n  json: {\n    customerName: extract(\"Name\"),\n    phoneNumber: extract(\"Phone Number\"),\n    country: extract(\"Country\"),\n    email: extract(\"Email\"),\n    contactTime: extract(\"Best Time to Call\"),\n    lookingTo: extract(\"Looking To\"),\n    propertyType: extract(\"Property Type\"),\n    budget: extract(\"Budget\"),\n    areas: extract(\"Preferred Areas\"),\n    readyOrOffplan: extract(\"Ready or Off-Plan\"),\n    timeline: extract(\"Timeline\")\n  }\n}];"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        -880,
        560
      ],
      "id": "c513c711-db5e-4f75-ae8a-89832de4e2e4",
      "name": "Code in JavaScript"
    },
    {
      "parameters": {
        "model": "llama-3.1-8b-instant",
        "options": {}
      },
      "type": "@n8n/n8n-nodes-langchain.lmChatGroq",
      "typeVersion": 1,
      "position": [
        -1696,
        592
      ],
      "id": "540fcf21-07ae-4299-a840-c846aa22d3e0",
      "name": "Groq Chat Model"
    }
  ],
  "pinData": {},
  "connections": {
    "Search Ready?": {
      "main": [
        [
          {
            "node": "Extract Search Parameters",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Send AI Response",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Format Properties for Telegram": {
      "main": [
        [
          {
            "node": "Send Properties to User",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Lead Ready?": {
      "main": [
        [
          {
            "node": "Code in JavaScript",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Search Ready?",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Prepare Lead Notification": {
      "main": [
        [
          {
            "node": "Notify Real Estate Team",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Notify Real Estate Team": {
      "main": [
        [
          {
            "node": "Confirm to Customer",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Telegram Trigger": {
      "main": [
        [
          {
            "node": "Dubai Real Estate AI Agent",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Extract Search Parameters": {
      "main": [
        [
          {
            "node": "HTTP Request",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "HTTP Request": {
      "main": [
        [
          {
            "node": "If",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Dubai Real Estate AI Agent": {
      "main": [
        [
          {
            "node": "Lead Ready?",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Simple Memory": {
      "ai_memory": [
        [
          {
            "node": "Dubai Real Estate AI Agent",
            "type": "ai_memory",
            "index": 0
          },
          {
            "node": "AI Agent",
            "type": "ai_memory",
            "index": 0
          }
        ]
      ]
    },
    "Edit Fields": {
      "main": [
        [
          {
            "node": "AI Agent",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "If": {
      "main": [
        [
          {
            "node": "Format Properties for Telegram",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Edit Fields",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "AI Agent": {
      "main": [
        [
          {
            "node": "Send a text message",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "HTTP Request1": {
      "ai_tool": [
        [
          {
            "node": "Dubai Real Estate AI Agent",
            "type": "ai_tool",
            "index": 0
          }
        ]
      ]
    },
    "Code in JavaScript": {
      "main": [
        [
          {
            "node": "Prepare Lead Notification",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Groq Chat Model": {
      "ai_languageModel": [
        [
          {
            "node": "AI Agent",
            "type": "ai_languageModel",
            "index": 0
          },
          {
            "node": "Dubai Real Estate AI Agent",
            "type": "ai_languageModel",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": false,
  "settings": {
    "executionOrder": "v1",
    "binaryMode": "separate",
    "availableInMCP": false
  },
  "versionId": "8bf3fa44-2afe-450a-bf20-2ce347c5a301",
  "meta": {
    "instanceId": "ea6f03c1e679a4302de0f2c6ae153dcf9d2a94883eba21745be8be24d6bf35f9"
  },
  "nodeGroups": [],
  "id": "tDIoTOfdoNE1EEEL",
  "tags": []
}
