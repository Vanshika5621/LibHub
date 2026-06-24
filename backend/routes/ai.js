const express = require('express');
const OpenAI = require('openai');
const { requireAuth, createServiceClient } = require('../utils/supabase');

const router = express.Router();

let openai = null;
if (process.env.OPENAI_API_KEY) {
  let apiKey = process.env.OPENAI_API_KEY.trim();
  // Remove any trailing colons or whitespaces
  if (apiKey.endsWith(':')) {
    apiKey = apiKey.slice(0, -1).trim();
  }
  
  if (apiKey && apiKey !== 'YOUR_OPENAI_API_KEY' && apiKey.startsWith('sk-')) {
    try {
      openai = new OpenAI({
        apiKey: apiKey,
      });
      console.log('✅ OpenAI Client initialized successfully with cleaned API key.');
    } catch (e) {
      console.error('❌ Failed to initialize OpenAI client:', e.message);
    }
  }
}

const SYSTEM_PROMPT = `You are the LibHub Senior Librarian 📚. Your goal is to provide expert, friendly, and precise assistance to our library members. 

CORE KNOWLEDGE:
* **Borrowing Policy**:
  - FREE Members: 2 books max, 7 days duration.
  - PREMIUM Members (₹299/mo): 5 books max, 21 days duration. Priority reservations.
  - VIP Members (₹599/mo): Unlimited books, 30 days duration. 2 fine waivers/month + Personal AI advisor.
* **Fines**: Flat rate of ₹10 per day for overdue items.
* **Navigation**: Tell users to look in 'Catalog' for new books, 'Borrowed' to return/renew, and 'Profile' to upgrade or pay fines.

RESPONSE STYLE:
- Professional yet warm. Use emojis sparingly.
- Use Markdown for structure (Bold, Lists, Headings).
- If you don't know a specific book, suggest exploring the Catalog.
- For inappropriate or off-topic queries, politely guide them back to library topics.`;

function getLocalResponse(message) {
  const msg = message.toLowerCase();
  
  if (msg.includes('limit') || msg.includes('how many') || msg.includes('maximum') || msg.includes('duration') || msg.includes('days')) {
    return `### 📋 Borrowing Limits & Durations
LibHub has the following borrowing limits based on your membership tier:
* **Free Tier:** Up to **2 books** at a time for **7 days**.
* **Premium Tier (Rs. 299/mo):** Up to **5 books** at a time for **21 days**.
* **VIP Tier (Rs. 599/mo):** **Unlimited books** at a time for **30 days**.

If you've hit your limit, you can return a book to borrow a new one or upgrade your plan in the **Profile** section!`;
  }
  
  if (msg.includes('fine') || msg.includes('late') || msg.includes('penalty') || msg.includes('fee') || msg.includes('charge')) {
    return `### 💰 Late Fines Policy
* The standard late return fine is **Rs. 10 per day** for all overdue books.
* Fines accumulate automatically after the due date.
* **VIP members** get **2 free fine waivers per month**!
* Fines can be paid securely using cards, UPI, or wallets in the **Profile** section under **My Fines**.`;
  }

  if (msg.includes('plan') || msg.includes('membership') || msg.includes('premium') || msg.includes('vip') || msg.includes('free') || msg.includes('cost') || msg.includes('price')) {
    return `### 🌟 Membership Plans
Choose a plan that fits your reading habits:
1. **Free Plan (Rs. 0):**
   * Limit: 2 books at a time
   * Duration: 7 days per book
2. **Premium Plan (Rs. 299/month):**
   * Limit: 5 books at a time
   * Duration: 21 days per book
   * Features: Priority book reservation, Ad-free experience
3. **VIP Plan (Rs. 599/month):**
   * Limit: **Unlimited books**
   * Duration: **30 days** per book
   * Features: 2 fine waivers per month, personalized AI recommendations, priority support

You can upgrade anytime using Razorpay in the **Profile** section.`;
  }

  if (msg.includes('info') || msg.includes('tell me about') || msg.includes('what is libhub') || msg.includes('about libhub')) {
    return `### 🏫 Welcome to LibHub!
LibHub is a modern digital library system designed to make reading accessible for everyone.

**Core Features:**
* 📚 **Borrow & Return:** Easily borrow hundreds of books and return them with one click.
* 🔖 **Reservations:** If a book is busy, hold your spot in the queue.
* 🤖 **AI Assistant:** Get instant support and book recommendations.
* 💳 **Smart Plans:** Choose between Free, Premium, and VIP memberships for better limits.
* 💰 **Fine Management:** Pay overdue fines directly within the app.

Is there anything specific you'd like to know about our plans or policies?`;
  }

  if (msg.includes('recommend') || msg.includes('suggest') || msg.includes('book') || msg.includes('read') || msg.includes('genre')) {
    return `### 📚 Recommended Books for You
Based on popular genres and top ratings, here are our top recommendations:
1. **Atomic Habits** by *James Clear* (Self-Help) - ⭐ 4.8
   * *A proven way to build good habits and break bad ones.*
2. **Sapiens** by *Yuval Noah Harari* (History) - ⭐ 4.6
   * *A brief history of humankind from the Stone Age to the present.*
3. **The God of Small Things** by *Arundhati Roy* (Fiction) - ⭐ 4.5
   * *A classic Indian fiction exploring childhood and societal laws.*
4. **Project Hail Mary** by *Andy Weir* (Sci-Fi) - ⭐ 4.6
   * *A gripping space adventure about saving humanity.*

Feel free to search for these titles in the **Books** tab!`;
  }

  if (msg.includes('return') || msg.includes('how to return') || msg.includes('give back')) {
    return `### 🔄 How to Return a Book
Returning books on LibHub is simple:
1. Go to the **Borrowed** tab (from the bottom navigation menu).
2. Find the book you want to return.
3. Click the **Return** button.
4. Your inventory will update immediately, and you can borrow your next book!`;
  }

  if (msg.includes('reserve') || msg.includes('queue') || msg.includes('hold')) {
    return `### 🔖 Book Reservations
* If a book is currently unavailable (out of stock), you will see a **Reserve** button on its detail page.
* Reserving a book places you in a waiting queue.
* When the book is returned and it's your turn, you will be notified, and the book status will change to **Ready to Borrow**.
* You can view and cancel your reservations in the **Borrowed** tab under the **Reserved** header.`;
  }

  return `### Hello! I'm your LibHub Assistant 🤖
I can help you with:
* **Borrowing limits** & durations ("What is the limit?")
* **Late fine** calculations ("How much is the fine?")
* **Membership plans** & pricing ("What is VIP?")
* **Book recommendations** ("Recommend a book")
* **Returning** or **reserving** books ("How to return?")

What would you like to know today?`;
}

// POST /api/ai/chat
router.post('/chat', requireAuth, async (req, res) => {
  const { messages } = req.body;
  const user = req.user;
  const serviceClient = createServiceClient();

  try {
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({ error: 'Messages array is required' });
    }

    const lastUserMessage = messages[messages.length - 1];

    if (!openai) {
      // Fallback for demo without API key
      const fallbackReply = getLocalResponse(lastUserMessage.content);
      
      // Save User msg in background
      await serviceClient.from('chat_history').insert({
        user_id: user.id,
        role: 'user',
        content: lastUserMessage.content,
      }).catch(() => {});

      // Save AI msg in background
      await serviceClient.from('chat_history').insert({
        user_id: user.id,
        role: 'assistant',
        content: fallbackReply,
      }).catch(() => {});

      return res.json({ 
        success: true, 
        message: {
          role: 'assistant',
          content: fallbackReply
        }
      });
    }

    // Format for OpenAI
    const aiMessages = [
      { role: 'system', content: SYSTEM_PROMPT },
      ...messages.map(m => ({ role: m.role, content: m.content }))
    ];

    // Wrap API call in a 4-second timeout promise to keep it fast
    const apiCall = openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: aiMessages,
      temperature: 0.7,
      max_tokens: 500,
    });

    const timeout = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('OpenAI Request Timeout')), 4000)
    );

    const response = await Promise.race([apiCall, timeout]);
    const aiMessage = response.choices[0].message;

    // Save User msg in background
    await serviceClient.from('chat_history').insert({
      user_id: user.id,
      role: 'user',
      content: lastUserMessage.content,
    }).catch(() => {});

    // Save AI msg in background
    await serviceClient.from('chat_history').insert({
      user_id: user.id,
      role: 'assistant',
      content: aiMessage.content,
    }).catch(() => {});

    return res.json({ success: true, message: aiMessage });
  } catch (error) {
    console.error('AI chat error (falling back to local response):', error.message);
    
    // In case of timeout or API failure, return local responder immediately
    const lastUserMessage = messages ? messages[messages.length - 1] : { content: '' };
    const fallbackReply = getLocalResponse(lastUserMessage.content);

    return res.json({ 
      success: true, 
      message: {
        role: 'assistant',
        content: fallbackReply
      }
    });
  }
});

module.exports = router;
