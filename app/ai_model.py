# app/ai_model.py
# Sample training data - we'll use this to train our AI model
training_data = [
    {"text": "huge pothole on main road near hospital", "category": "pothole"},
    {"text": "garbage pile growing on street corner", "category": "garbage"},
    {"text": "street light not working for 3 days", "category": "broken_streetlight"},
    {"text": "water leakage from broken pipe", "category": "water_leakage"},
    {"text": "graffiti on public walls", "category": "graffiti"},
    {"text": "road damaged with cracks", "category": "road_damage"},
    {"text": "trash not collected for a week", "category": "garbage"},
    {"text": "broken traffic signal causing chaos", "category": "traffic_signal"},
    {"text": "deep pothole damaging vehicles", "category": "pothole"},
    {"text": "street light pole bent and dangerous", "category": "broken_streetlight"}
]

# This is a simple AI classifier (we'll improve it later)
def predict_category(text_description):
    """Simple rule-based classifier for now - we'll replace with real ML later"""
    text = text_description.lower()
    
    if "pothole" in text:
        return "pothole"
    elif "garbage" in text or "trash" in text:
        return "garbage"
    elif "street light" in text or "light" in text:
        return "broken_streetlight"
    elif "water" in text or "leak" in text:
        return "water_leakage"
    elif "graffiti" in text:
        return "graffiti"
    elif "road" in text or "crack" in text:
        return "road_damage"
    elif "traffic" in text or "signal" in text:
        return "traffic_signal"
    else:
        return "other"