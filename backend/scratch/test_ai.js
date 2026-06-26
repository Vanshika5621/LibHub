require('dotenv').config();
const OpenAI = require('openai');

async function test() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey || apiKey === 'YOUR_OPENAI_API_KEY') {
    console.log('❌ No API key found');
    return;
  }
  
  try {
    const openai = new OpenAI({ apiKey });
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: 'hello' }],
      max_tokens: 5,
    });
    console.log('✅ AI key is working!');
    console.log('Response:', response.choices[0].message.content);
  } catch (e) {
    console.log('❌ AI key error:', e.message);
  }
}

test();
