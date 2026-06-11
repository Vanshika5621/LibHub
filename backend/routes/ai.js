const express = require('express');
const OpenAI = require('openai');
const { requireAuth, createServiceClient } = require('../utils/supabase');

const router = express.Router();

let openai = null;
if (process.env.OPENAI_API_KEY) {
  openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
  });
}

const SYSTEM_PROMPT = `You are a helpful and knowledgeable digital library assistant for LibHub.
You help users find books, understand library policies (like borrowing limits and fines), 
and recommend reading materials. Be concise, friendly, and structure your responses with markdown.
Membership Tiers:
- Free: 2 books limit, 7 days duration.
- Premium: 5 books limit, 21 days duration. (Rs. 299)
- VIP: Unlimited books, 30 days duration. (Rs. 599)
Late fine is Rs. 10 per day.`;

// POST /api/ai/chat
router.post('/chat', requireAuth, async (req, res) => {
  try {
    const { messages } = req.body;
    const user = req.user;

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({ error: 'Messages array is required' });
    }

    if (!openai) {
      // Fallback for demo without API key
      return res.json({ 
        success: true, 
        message: {
          role: 'assistant',
          content: 'I am the LibHub AI Assistant. (Note: OpenAI API key is missing from backend configuration, so this is a fallback response. To get real AI responses, please add OPENAI_API_KEY to your .env file.)'
        }
      });
    }

    // Format for OpenAI
    const aiMessages = [
      { role: 'system', content: SYSTEM_PROMPT },
      ...messages.map(m => ({ role: m.role, content: m.content }))
    ];

    const response = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: aiMessages,
      temperature: 0.7,
      max_tokens: 500,
    });

    const aiMessage = response.choices[0].message;

    // Save user's last message and AI response to Supabase
    const serviceClient = createServiceClient();
    const lastUserMessage = messages[messages.length - 1];
    
    // Save User msg
    await serviceClient.from('chat_history').insert({
      user_id: user.id,
      role: 'user',
      content: lastUserMessage.content,
    });

    // Save AI msg
    await serviceClient.from('chat_history').insert({
      user_id: user.id,
      role: 'assistant',
      content: aiMessage.content,
    });

    return res.json({ success: true, message: aiMessage });
  } catch (error) {
    console.error('AI chat error:', error);
    return res.status(500).json({ error: 'Failed to process chat' });
  }
});

module.exports = router;
