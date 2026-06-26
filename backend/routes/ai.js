const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { requireAuth, createServiceClient } = require('../utils/supabase');

const router = express.Router();

let genAI = null;
let model = null;

if (process.env.GEMINI_API_KEY) {
  try {
    const apiKey = process.env.GEMINI_API_KEY.trim();
    genAI = new GoogleGenerativeAI(apiKey);
    model = genAI.getGenerativeModel({ model: "gemini-flash-latest" });
    console.log('✅ Google Gemini Client initialized.');
  } catch (e) {
    console.error('❌ Failed to initialize Gemini:', e.message);
  }
}

const SYSTEM_INSTRUCTIONS = `You are the LibHub Gemini Librarian 2.0 📚. Your goal is to provide expert, friendly, and precise assistance to our library members. 
ALWAYS identify yourself as 'Gemini Librarian 2.0' if asked for your name.

CORE KNOWLEDGE:
* **Borrowing Policy**:
  - FREE Members: 2 books max, 7 days.
  - PREMIUM Members (₹299/mo): 5 books max, 21 days.
  - VIP Members (₹599/mo): Unlimited books, 30 days. Fine waivers available.
* **Fines**: ₹10 per day for overdue items.
* **Navigation**: 'Catalog' for new books, 'Borrowed' to return/renew, 'Profile' for fines/plans.

RESPONSE STYLE:
- Professional and warm librarian tone.
- Use Markdown structure.
- If unsure about a specific book, suggest exploring the Catalog.`;

async function getLocalResponse(msg, serviceClient) {
  const msgLower = msg.toLowerCase();

  if (msgLower.includes('membership') || msgLower.includes('plan')) {
    return `### 💳 Membership Plans\n* **Free**: 2 books, 7 days.\n* **Premium (₹299/mo)**: 5 books, 21 days.\n* **VIP (₹599/mo)**: Unlimited books, 30 days.`;
  }
  
  if (msgLower.includes('fine')) {
    return `### 💸 Fine Policy\nOverdue books incur a fine of **₹10 per day**. You can pay fines in the **Profile** tab.`;
  }

  if (msgLower.includes('borrow') || msgLower.includes('return')) {
    return `### 🔄 Borrow & Return\n1. Find a book in **Catalog**.\n2. Tap **Borrow**.\n3. Return books from the **Borrowed** tab.`;
  }

  if (msgLower.includes('tell me about') || msgLower.includes('info on') || msgLower.includes('who wrote')) {
    let query = msgLower.replace('tell me about', '').replace('info on', '').replace('who wrote', '').replace('book', '').replace('tha', '').replace('the', '').trim();
    if (query.length > 2) {
      try {
        const { data: books } = await serviceClient
          .from('books')
          .select('*')
          .or(`title.ilike.%${query}%,author.ilike.%${query}%`)
          .limit(1);
          
        if (books && books.length > 0) {
          const b = books[0];
          return `### 📖 Book Details: ${b.title}\n* **Author:** ${b.author}\n* **Genre:** ${b.genre}\n* **Rating:** ⭐ ${b.rating}\n* **Description:** ${b.description}`;
        }
      } catch (e) {}
    }
  }

  return `### 📚 Welcome to LibHub AI Assistant
Hello! I am your dedicated Librarian. How can I assist you today?

**You can ask me things like:**
* 📖 "Tell me about the **Clean Code** book"
* 🏷️ "What are the **membership plans**?"
* 💸 "Tell me about **fines** and policies"

*Note: Our AI service is currently very busy, but I can still help with general library rules!*`;
}

router.post('/chat', requireAuth, async (req, res) => {
  const { messages } = req.body;
  const user = req.user;
  const serviceClient = createServiceClient();
  const lastUserMessage = messages[messages.length - 1];
  console.log('🤖 AI Request received:', lastUserMessage.content);

  try {
    if (!model) {
      const fallbackReply = await getLocalResponse(lastUserMessage.content, serviceClient);
      return res.json({ success: true, message: { role: 'assistant', content: fallbackReply } });
    }

    const history = messages.slice(0, -1).map(m => ({ 
      role: m.role === 'user' ? 'user' : 'model', 
      parts: [{ text: m.content }] 
    }));
    
    // Ensure history roles alternate correctly for Gemini SDK
    const chat = model.startChat({ history });

    let result;
    let retries = 3;
    
    while (retries > 0) {
      try {
        result = await chat.sendMessage(lastUserMessage.content);
        break; 
      } catch (err) {
        if (err.message.includes('503') || err.message.includes('Service Unavailable') || err.message.includes('busy')) {
          console.log(`⚠️ Gemini busy, retrying... (${retries} left)`);
          retries--;
          await new Promise(resolve => setTimeout(resolve, 2000));
        } else {
          throw err;
        }
      }
    }

    if (!result) throw new Error("Gemini service is too busy right now.");

    const response = await result.response;
    const aiText = response.text();

    return res.json({ success: true, message: { role: 'assistant', content: aiText } });
  } catch (error) {
    console.error('Gemini API Error:', error.message);
    const fallbackReply = await getLocalResponse(lastUserMessage.content, serviceClient);
    return res.json({ success: true, message: { role: 'assistant', content: fallbackReply } });
  }
});

module.exports = router;
