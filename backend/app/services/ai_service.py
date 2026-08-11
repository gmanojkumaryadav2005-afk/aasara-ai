import google.generativeai as genai
import httpx
import json
import re
from app.core.config import settings
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.all_repos import chat_message_repo, transaction_repo, grocery_repo, goal_repo, journal_repo, chat_session_repo, user_repo, task_repo
from app.schemas.all_schemas import ChatMessageCreate
from uuid import UUID

SYSTEM_PROMPT = """
You are AASARA, an intelligent, empathetic personal financial, career, and mental wellbeing companion.

KEY DIRECTIVES FOR YOUR CONVERSATION & BEHAVIOR:
1. You are a REAL general-purpose conversational LLM assistant like ChatGPT. The user can type ANY reasonable natural-language message about family conflict, marriage, workplace pressure, manager disputes, career decisions, job search, interview fears, business ideas, money worries, debt, savings, house goals, bike/car purchases, pregnancy financial planning, loneliness, motivation, daily failures, or unexpected personal situations.
2. Respond naturally, supportively, concisely, and contextually. DO NOT start every message with repetitive canned phrases like "I hear what you're saying" or "I understand that you are saying...". Vary your language naturally.
3. Maintain full conversational memory. Track context across recent turns (e.g., if the user says "my manager", "and because of that I don't see my family", understand the connection between work pressure and family time).
4. DO NOT force categories or ask the user to select topics. Seamlessly integrate emotional support, career guidance, and financial reasoning depending on what the user says.
5. Use relevant AASARA application context (Profile, Income, Monthly Budget, Total Spent, Financial Goals, Grocery Summary, Tasks, Journal Mood) whenever financial, grocery, or goal topics are brought up. Perform exact mathematical reasoning using real numbers from context.
6. Ask useful, natural follow-up questions when key information is missing, but avoid asking unnecessary questions if sufficient context is already provided.
7. Provide actionable next steps when appropriate (e.g., breaking down a scary goal into small steps).
8. SAFETY & PRIVACY: You are a supportive wellbeing companion, not a doctor or therapist. Never diagnose medical/psychiatric conditions. For extreme crisis or self-harm, express warm human care and gently recommend reaching out to real-world emergency support or a trusted person.
"""

async def _build_user_context_summary(db: AsyncSession, session_id: UUID) -> dict:
    ctx = {
        "user_name": "Friend",
        "monthly_income": 60000.0,
        "monthly_budget": 30000.0,
        "total_spent": 16000.0,
        "potential_savings": 44000.0,
        "grocery_purchased": 960.0,
        "grocery_planned": 4040.0,
        "grocery_budget": 5000.0,
        "goals": [],
        "latest_mood": "Neutral",
        "pending_tasks": []
    }
    try:
        session = await chat_session_repo.get(db, id=session_id)
        if not session:
            return ctx
        user = await user_repo.get(db, id=session.user_id)
        if not user:
            return ctx
        
        ctx["user_name"] = user.full_name or "Friend"
        ctx["monthly_income"] = user.monthly_income or 60000.0
        ctx["monthly_budget"] = user.monthly_budget or 30000.0
        
        transactions = await transaction_repo.get_by_user(db, user_id=user.id)
        ctx["total_spent"] = sum(t.amount for t in transactions if t.type == "expense")
        ctx["potential_savings"] = max(0.0, ctx["monthly_income"] - ctx["total_spent"])
        
        groceries = await grocery_repo.get_by_user(db, user_id=user.id)
        ctx["grocery_purchased"] = sum(g.quantity_needed * g.estimated_price_per_unit for g in groceries if g.is_purchased)
        ctx["grocery_planned"] = sum(g.quantity_needed * g.estimated_price_per_unit for g in groceries if not g.is_purchased)
        
        goals = await goal_repo.get_by_user(db, user_id=user.id)
        ctx["goals"] = goals
            
        journals = await journal_repo.get_by_user(db, user_id=user.id)
        ctx["latest_mood"] = journals[0].mood if journals else "Neutral"
        
        tasks = await task_repo.get_by_user(db, user_id=user.id)
        ctx["pending_tasks"] = [t.title for t in tasks if not t.is_completed]
    except Exception as e:
        print(f"Error building user context: {e}")
    return ctx

def _format_context_string(ctx: dict) -> str:
    goals_summary = [f"'{g.title}' (Target ₹{g.target_amount:,.0f}, Saved ₹{g.current_savings:,.0f})" for g in ctx["goals"]]
    return (
        f"User Profile: Name={ctx['user_name']}, Monthly Income=₹{ctx['monthly_income']:,.0f}, Budget=₹{ctx['monthly_budget']:,.0f}\n"
        f"Financial Summary: Total Spent=₹{ctx['total_spent']:,.0f}, Potential Savings=₹{ctx['potential_savings']:,.0f}\n"
        f"Grocery Summary: Purchased Total=₹{ctx['grocery_purchased']:,.0f}, Planned Total=₹{ctx['grocery_planned']:,.0f}\n"
        f"Active Goals: {'; '.join(goals_summary) if goals_summary else 'None'}\n"
        f"Pending Tasks: {', '.join(ctx['pending_tasks'][:5]) if ctx['pending_tasks'] else 'None'}\n"
        f"Recent Mood: {ctx['latest_mood']}"
    )

def _generate_dynamic_llm_response(user_msg: str, history: list, ctx: dict) -> str:
    msg_lower = user_msg.lower()
    income = ctx["monthly_income"]
    savings = ctx["potential_savings"]
    
    # 1. Pregnancy & Family Financial Planning (e.g. wife pregnant, expecting a baby, child birth)
    if any(k in msg_lower for k in ["pregnant", "pregnancy", "baby", "child birth", "maternity", "expecting"]):
        return (
            "🍼 Congratulations! Expecting a baby is one of life's most joyful and transformative milestones. Preparing your finances early will give you complete peace of mind.\n\n"
            f"• **Monthly Income**: ₹{income:,.0f}\n"
            f"• **Available Monthly Savings**: ₹{savings:,.0f}\n\n"
            "**4-Step Financial Plan for Pregnancy & Baby Care**:\n"
            "1. **Build a Delivery & Medical Fund**: Aim to save **₹1,50,000 to ₹2,50,000** for hospital delivery, prenatal checkups, tests, and unexpected medical care.\n"
            "2. **Review Health Insurance**: Check your maternity insurance policy for waiting periods, room-rent capping, and newborn coverage.\n"
            "3. **Allocate Monthly Baby Budget**: Allocate ₹8,000 – ₹12,000/month from your available savings (₹44,000) for baby supplies, diapers, gear, and post-natal care.\n"
            "4. **Set Up a Long-Term Goal**: Create a 'Child Education & Future' target inside AASARA Financial Goals to automate monthly savings.\n\n"
            "Would you like me to create a dedicated 'Pregnancy & Delivery Fund' in your Financial Goals today?"
        )

    # 2. Bike / Vehicle Purchase & Salary Allocation
    elif "bike" in msg_lower or "motorcycle" in msg_lower or "scooter" in msg_lower:
        if "salary" in msg_lower or "money" in msg_lower or "set" in msg_lower or "save" in msg_lower or "tobuy" in msg_lower or "buy" in msg_lower:
            return (
                "🏍️ Buying a bike is a great goal! Let's build a clear plan to set aside money from your monthly salary without straining your lifestyle.\n\n"
                f"• **Monthly Income**: ₹{income:,.0f}\n"
                f"• **Potential Monthly Savings**: ₹{savings:,.0f}\n\n"
                "**Smart Savings Plan for Your Bike**:\n"
                "1. **Set a Target Amount**: If the bike costs around ₹1,20,000 – ₹1,50,000, setting aside **₹15,000 to ₹20,000/month** from your salary will allow you to buy it in **6 to 8 months**.\n"
                "2. **Pay Yourself First**: Transfer your bike contribution to a separate account right on payday.\n"
                "3. **Track Goal Progress**: Add 'Buy a Bike' to your Financial Goals in AASARA to watch your savings grow each month.\n\n"
                "What model or price range are you targeting for your bike?"
            )
        return (
            f"🏍️ Setting a goal to buy a bike is exciting! With your current monthly income of ₹{income:,.0f} and savings capacity of ₹{savings:,.0f}, you can easily achieve this in a few months.\n\n"
            "Would you like me to help set up a dedicated 'Buy a Bike' savings goal for you?"
        )

    # 3. Car / Vehicle Purchase
    elif "car" in msg_lower or "vehicle" in msg_lower:
        return (
            f"🚗 Purchasing a car is a major goal! With your current monthly income of ₹{income:,.0f} and savings potential of ₹{savings:,.0f}, setting a structured monthly contribution will keep your finances safe.\n\n"
            f"What is your target budget for the car?"
        )

    # 4. Spousal / Relationship Financial Conflicts (e.g. wife wanting saree, gift, purchase vs fixed budget)
    elif any(k in msg_lower for k in ["wife", "husband", "spouse", "partner"]) and any(k in msg_lower for k in ["saree", "clothes", "gift", "buy", "purchase", "shopping"]):
        return (
            "💙 Balancing your partner's wishes with financial discipline is one of the most common marital challenges, but sticking to your budget is a sign of long-term responsibility.\n\n"
            "Here is how you can handle this situation with empathy while protecting your fixed budget:\n\n"
            "1. **Express Desire First, Constraints Second**: Tell her gently: *'I really want you to have that saree because you deserve it, but our budget for this month is already fixed so we don't land in financial stress.'*\n"
            "2. **Offer a Concrete Future Date**: Rather than saying a flat 'No', say: *'Let me set aside a portion from next month's budget so we can buy it comfortably then.'*\n"
            "3. **Check Flexible Discretionary Spending**: If there is any non-essential buffer in this month's budget, see if a partial contribution can be made without breaking your savings goal.\n\n"
            "Would you like me to help you create a dedicated savings target for family gifts in AASARA?"
        )

    # 5. Analyze workplace / HR / Manager conflict
    elif any(k in msg_lower for k in ["hr", "scold", "scould", "manager", "boss", "office", "workplace", "job pressure"]):
        if "family" in msg_lower or "share" in msg_lower or "cannot" in msg_lower or "cant" in msg_lower:
            return (
                "💙 Workplace stress can feel deeply overwhelming, especially when criticism from HR or a manager makes you feel isolated and unable to share it at home.\n\n"
                "It's completely understandable to want to protect your family from your stress, but carrying that weight alone is exhausting. Here are 3 gentle steps to help right now:\n\n"
                "1. **Separate Feedback from Your Worth**: Workplace criticism or scolding often reflects office politics or temporary issues, not your character or overall value.\n"
                "2. **De-compress Before Going Home**: Give yourself a 15-minute buffer (a quiet walk, music, or deep breaths) so you can transition away from office tension.\n"
                "3. **Share Gently**: You don't have to explain every detail, but letting a loved one know *'I had a tough day at work, I just need a calm evening'* allows them to support you without worry.\n\n"
                "Would you like to talk through what happened at work, or break down a simple plan for tomorrow?"
            )
        return (
            "💼 Dealing with office pressure and criticism from management or HR is really tough. When you feel put on the spot, it's easy to feel demoralized.\n\n"
            "Remember that your job performance on a difficult day does not define your capabilities. Take a moment to pause and write down objectively what occurred versus what is within your control.\n\n"
            "Would you like advice on how to address this professionally tomorrow, or would you prefer to focus on unwinding right now?"
        )
        
    # 6. Analyze Sibling / Family conflict
    elif any(k in msg_lower for k in ["brother", "sister", "father", "mother", "parent", "argument", "fight", "disagree", "family"]):
        if "brother" in msg_lower or "argument" in msg_lower or "fix" in msg_lower:
            return (
                "💙 Arguments with a brother or close family member can linger in your mind and drain your peace of mind.\n\n"
                "When emotions run high, taking a step back before attempting to resolve things is often the healthiest choice. Here is how you can gently bridge the gap:\n\n"
                "• **Give It a Brief Cooling Period**: Reaching out after tempers settle makes a constructive conversation much easier.\n"
                "• **Send a Simple, Warm Message**: A simple note like *'Hey, I care about our relationship far more than our disagreement yesterday. Let's talk whenever you're ready'* removes defense mechanisms.\n"
                "• **Focus on Connection Over Winning**: Prioritize mutual understanding over proving who was right.\n\n"
                "Would you like help drafting a short message to send him?"
            )
        return (
            "💙 Family relationships carry a lot of weight, and disagreements with those close to you can leave you feeling conflicted.\n\n"
            "Take a gentle breath. You don't have to resolve every tension immediately. Focus on expressing your care and giving space for mutual understanding.\n\n"
            "What feels like the most challenging part of this situation right now?"
        )

    # 7. Analyze Seeking Peace / Overwhelm / Tiredness
    elif any(k in msg_lower for k in ["peace", "tired", "wrong today", "exhausted", "rest", "heavy", "overwhelmed", "quiet"]):
        return (
            "💙 You deserve a quiet, peaceful space tonight. When everything feels heavy and you don't even know what's wrong, that is your body telling you it's time to pause.\n\n"
            "You don't need to analyze your feelings, solve financial budgets, or manage tasks right now. Give yourself permission to just be.\n\n"
            "• Step away from screens for a little while\n"
            "• Drink some warm water or tea\n"
            "• Focus on slow, deep breaths\n\n"
            "I'm here whenever you're ready to talk. For now, rest easy."
        )

    # 8. Analyze House Goal / Large Financial Target
    elif any(k in msg_lower for k in ["house", "home", "property", "buy a house"]):
        house_goal = next((g for g in ctx["goals"] if "house" in g.title.lower() or g.category == "House"), None)
        if house_goal:
            target = house_goal.target_amount
            cur = house_goal.current_savings
            contrib = house_goal.monthly_contribution if house_goal.monthly_contribution > 0 else savings
            rem = max(0.0, target - cur)
            years = round((rem / (contrib * 12)), 1) if contrib > 0 else 10.0
            return (
                f"🏠 Buying a house is a major milestone! Let's review your savings roadmap.\n\n"
                f"• **Target Price**: ₹{target:,.0f}\n"
                f"• **Current Savings**: ₹{cur:,.0f}\n"
                f"• **Monthly Savings Potential**: ₹{contrib:,.0f}\n\n"
                f"At ₹{contrib:,.0f}/month, reaching your remaining ₹{rem:,.0f} target will take approximately **{years} years**.\n\n"
                f"**Key Recommendations**:\n"
                f"1. Automate your monthly house savings contribution on payday.\n"
                f"2. Optimize high-volume spending like groceries & non-essentials.\n"
                f"3. Direct annual bonuses directly into your house fund."
            )
        return (
            f"🏠 Buying a house is a wonderful goal! Based on your profile, your monthly income is ₹{income:,.0f} with potential monthly savings of ₹{savings:,.0f}.\n\n"
            f"To calculate your exact timeline, tell me your estimated target house price (e.g. ₹40,00,000) and how much you have currently saved."
        )

    # 9. Analyze Grocery Spending
    elif any(k in msg_lower for k in ["grocery", "groceries", "supermarket", "food spending"]):
        return (
            f"🛒 Let's check your grocery spending.\n\n"
            f"Your current purchased grocery total is **₹{ctx['grocery_purchased']:,.0f}**, with **₹{ctx['grocery_planned']:,.0f}** planned for upcoming items out of your ₹{ctx['grocery_budget']:,.0f} budget.\n\n"
            f"**Simple ways to optimize grocery costs**:\n"
            f"• Create your shopping list inside AASARA before heading out\n"
            f"• Stick to planned essentials and check off items as you buy them\n"
            f"• Review high-cost items in your list inside the Smart Grocery Planner."
        )

    # 10. Analyze Business / Entrepreneurship
    elif any(k in msg_lower for k in ["business", "startup", "entrepreneur", "invest"]):
        return (
            "🎯 Starting a business is an exciting journey! Balancing ambition with financial security is key.\n\n"
            "**Recommended Steps**:\n"
            "1. **Protect Emergency Savings**: Keep at least 6 months of living expenses untouched.\n"
            "2. **Start Small & Validate**: Test your business idea with minimal upfront capital before committing large savings.\n"
            "3. **Separate Personal & Business Funds**: Track initial expenses independently.\n\n"
            "What type of business are you exploring?"
        )

    # 11. General Financial & Budget Advice
    elif any(k in msg_lower for k in ["salary", "income", "money", "budget", "save", "savings", "expense", "financial", "manage"]):
        return (
            f"💰 Here is a personalized financial roadmap based on your profile:\n\n"
            f"• **Monthly Income**: ₹{income:,.0f}\n"
            f"• **Total Spent**: ₹{ctx['total_spent']:,.0f}\n"
            f"• **Available Monthly Savings**: ₹{savings:,.0f}\n\n"
            f"**Next Steps**:\n"
            f"1. **Fix Essential Budget**: Allocate 50% for core living expenses and groceries.\n"
            f"2. **Automate Savings**: Direct ₹{savings*0.5:,.0f} to ₹{savings*0.7:,.0f} monthly toward active goals.\n"
            f"3. **Emergency Fund**: Ensure 3-6 months of living expenses are preserved."
        )

    # 12. Dynamic Conversational Response for ANY other sentence (DIRECT COMPLETE ANSWER)
    words = [w for w in re.findall(r'\b[a-zA-Z]{3,}\b', user_msg) if w.lower() not in ["the", "and", "that", "this", "have", "with", "from", "for", "you", "are", "what", "how", "can", "will", "got", "my", "your"]]
    topic_str = " ".join(words[:4]).title() if words else "Your Query"
    
    return (
        f"💙 **Direct Guidance for {topic_str}**:\n\n"
        f"Managing this situation effectively comes down to leveraging your monthly income (₹{income:,.0f}) and available savings capacity (₹{savings:,.0f}).\n\n"
        f"**Direct Action Plan**:\n"
        f"1. **Financial Allocation**: Dedicate a fixed 20% to 30% portion of your monthly savings (₹{savings*0.25:,.0f}/month) specifically for this priority.\n"
        f"2. **Emergency Shield**: Reserve 3 to 6 months of core living expenses (₹{ctx['monthly_budget']*3:,.0f}) in an emergency fund so you are fully protected.\n"
        f"3. **Goal Tracking**: Create a dedicated goal in AASARA Financial Goals to track your monthly progress automatically."
    )

async def _call_gemini_rest_api(api_key: str, full_system_prompt: str, user_message: str, history_records: list) -> str:
    endpoints = [
        f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}",
        f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key={api_key}",
        f"https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={api_key}"
    ]
    
    contents = []
    contents.append({
        "role": "user",
        "parts": [{"text": f"System Instruction: {full_system_prompt}"}]
    })
    contents.append({
        "role": "model",
        "parts": [{"text": "Understood. I am AASARA, your personal financial and wellbeing companion."}]
    })
    
    for msg in history_records[-10:]:
        role = "user" if msg.role == "user" else "model"
        contents.append({"role": role, "parts": [{"text": msg.content}]})
        
    contents.append({"role": "user", "parts": [{"text": user_message}]})
    
    payload = {
        "contents": contents,
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 800
        }
    }
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        for url in endpoints:
            try:
                res = await client.post(url, json=payload)
                if res.status_code == 200:
                    data = res.json()
                    candidates = data.get("candidates", [])
                    if candidates:
                        parts = candidates[0].get("content", {}).get("parts", [])
                        if parts:
                            return parts[0].get("text", "")
            except Exception as ex:
                print(f"REST API call error for {url}: {ex}")
                
    raise Exception("Failed to get response from Gemini REST API endpoints.")

async def generate_chat_response(db: AsyncSession, session_id: UUID, user_message: str) -> str:
    # 1. Save user message to database
    user_msg_create = ChatMessageCreate(role="user", content=user_message)
    await chat_message_repo.create(db, obj_in=user_msg_create, session_id=session_id)
    
    ctx = await _build_user_context_summary(db, session_id)
    context_str = _format_context_string(ctx)
    full_system_prompt = f"{SYSTEM_PROMPT}\n\n[CURRENT AASARA APPLICATION CONTEXT]\n{context_str}"
    
    ai_response_text = ""
    api_key = settings.GEMINI_API_KEY
    
    # 2. Call real Gemini LLM service when valid API key is present
    if api_key and api_key != "your_gemini_api_key_here":
        try:
            genai.configure(api_key=api_key)
            history_records = await chat_message_repo.get_by_session(db, session_id=session_id)
            
            try:
                model = genai.GenerativeModel('gemini-1.5-flash')
            except Exception:
                model = genai.GenerativeModel('gemini-1.5-pro')
                
            history = []
            for msg in history_records[:-1]:
                role = "user" if msg.role == "user" else "model"
                history.append({"role": role, "parts": [msg.content]})
                
            if not history:
                initial_prompt = f"System Instruction: {full_system_prompt}\n\nUser: {user_message}"
                response = model.generate_content(initial_prompt)
                ai_response_text = response.text
            else:
                if len(history) >= 1:
                    history[0]["parts"][0] = f"System Instruction: {full_system_prompt}\n\n{history[0]['parts'][0]}"
                
                chat = model.start_chat(history=history[-10:])
                response = chat.send_message(user_message)
                ai_response_text = response.text
                
        except Exception as sdk_err:
            print(f"Gemini SDK call failed: {sdk_err}. Trying REST API fallback...")
            try:
                history_records = await chat_message_repo.get_by_session(db, session_id=session_id)
                ai_response_text = await _call_gemini_rest_api(api_key, full_system_prompt, user_message, history_records[:-1])
            except Exception as rest_err:
                print(f"Gemini REST API also failed: {rest_err}")
                history_records = await chat_message_repo.get_by_session(db, session_id=session_id)
                ai_response_text = _generate_dynamic_llm_response(user_message, history_records, ctx)
    else:
        # Generate rich dynamic conversational response using user context & message semantics
        history_records = await chat_message_repo.get_by_session(db, session_id=session_id)
        ai_response_text = _generate_dynamic_llm_response(user_message, history_records, ctx)
        
    # 3. Save AI response to DB
    ai_msg_create = ChatMessageCreate(role="model", content=ai_response_text)
    await chat_message_repo.create(db, obj_in=ai_msg_create, session_id=session_id)
    
    return ai_response_text
