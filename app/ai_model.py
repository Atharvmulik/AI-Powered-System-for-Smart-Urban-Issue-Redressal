# app/ai_model.py
# Sample training data - we'll use this to train our AI model
training_data = [
    {"text": "huge pothole on main road near hospital", "category": "Infrastructure"},
    {"text": "garbage pile growing on street corner", "category": "Sanitation"},
    {"text": "street light not working for 3 days", "category": "Infrastructure"},
    {"text": "water leakage from broken pipe", "category": "Utilities"},
    {"text": "graffiti on public walls", "category": "Public Safety"},
    {"text": "road damaged with cracks", "category": "Infrastructure"},
    {"text": "trash not collected for a week", "category": "Sanitation"},
    {"text": "broken traffic signal causing chaos", "category": "Public Safety"},
    {"text": "deep pothole damaging vehicles", "category": "Infrastructure"},
    {"text": "street light pole bent and dangerous", "category": "Infrastructure"},
    {"text": "park bench broken and needs repair", "category": "Environment"},
    {"text": "air pollution from factory smoke", "category": "Environment"},
    {"text": "unsafe sidewalk with uneven pavement", "category": "Infrastructure"},
    {"text": "stray animals causing nuisance", "category": "Public Safety"},
    {"text": "water supply interrupted", "category": "Utilities"}
]

# This is a simple AI classifier
def predict_category(text_description):
    """Simple rule-based classifier for now - we'll replace with real ML later"""
    text = text_description.lower()
    
    if "pothole" in text or "road" in text or "street" in text or "bridge" in text:
        return "Infrastructure"
    elif "garbage" in text or "trash" in text or "waste" in text or "clean" in text:
        return "Sanitation"
    elif "water" in text or "pipe" in text or "leak" in text or "supply" in text:
        return "Utilities"
    elif "safety" in text or "crime" in text or "police" in text or "security" in text:
        return "Public Safety"
    elif "park" in text or "tree" in text or "environment" in text or "pollution" in text:
        return "Environment"
    else:
        return "Infrastructure"  # Default category