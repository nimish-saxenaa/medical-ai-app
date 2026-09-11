var a = {
  "session_id": "f73130f9-1e5e-41fa-bc9a-dfa6ef2353a7",
  "doctor_id": "6a72f7db64d34c80ea41fdab",
  "patient_id": "98660607-67dd-42df-a5a4-d5b08ebf1960",
  "patient_name": "New Patient",
  "specialty": "general_medicine",
  "status": "interrupted",
  "workflow": "draft",
  "created_at": "2026-09-01T10:35:17.135849",
  "ended_at": "2026-09-01T10:46:41.491390",
  "consent_captured_at": "2026-09-01T10:35:17.131128",
  "utterances": [
    {
      "utterance_id": "1236694fff2648c182b0412b938a5f4c",
      "seq": 0,
      "text": "Hello.",
      "role": "doctor",
      "role_confidence": 0.9,
      "role_source": "diarizer",
      "language": "it",
      "speaker_id": null,
      "started_at": 1.839,
      "ended_at": 2.24,
      "created_at": "2026-09-01T10:35:38.703846",
    },
    {
      "utterance_id": "a5f73e5eed76491a8480e3c7df0ff4d4",
      "seq": 1,
      "text": "क्या हो रहा है आपको?",
      "role": "doctor",
      "role_confidence": 0.9,
      "role_source": "diarizer",
      "language": "hi",
      "speaker_id": null,
      "started_at": 10.275,
      "ended_at": 11.515,
      "created_at": "2026-09-01T10:35:48.015752",
    },
  ],
  "panel": {
    "symptoms": [
      {
        "name": "headache",
        "detail": "heavy, upper location",
        "reported_by": "patient",
      },
    ],
    "diagnoses": [
      {
        "condition": "cancer",
        "likelihood": "suspected",
        "reasoning":
            "Doctor suggests patient may have cancer, possibly first stage, based on symptoms of headache, abdominal pain with burning sensation, and history of ulcers",
        "icd_code": null,
      },
    ],
    "tests": [
      {"name": "blood test", "status": "ordered"},
      {"name": "vitamin test", "status": "ordered"},
    ],
    "medications": [
      {
        "drug_name": "paracetamol",
        "dose": null,
        "frequency": "three days",
        "action": "start",
        "note": null,
      },
      {
        "drug_name": "cup syrup",
        "dose": null,
        "frequency": "daily",
        "action": "start",
        "note": null,
      },
    ],
    "questions_asked": [
      {"text": "ये सर दर्द कितने वक्त से कर रहा है?", "area": "onset"},
      {"text": "ये किस तरह से दर्द करता है?", "area": "character"},
      {"text": "क्या आपने इसके लिए कोई दवाई खाई है?", "area": "medications"},
      {
        "text": "क्या आपको इस तरह सर दर्द बहुत बार होता है?",
        "area": "frequency",
      },
      {"text": "यह पेट दर्द आपको कब से हो रहा है?", "area": "onset"},
      {"text": "क्या आपको पेट में जलन लगती है?", "area": "character"},
      {
        "text": "क्या ये आपको तीखा खाने पर होता है या फिर ज्यादा खाने पर?",
        "area": "trigger",
      },
      {
        "text": "क्या आपने इससे पहले कहीं इलाज करवाया है?",
        "area": "past treatment",
      },
      {"text": "क्या आपको अभी भी छाले हैं?", "area": "current status"},
    ],
    "updated_at": "2026-09-01T10:57:26.511198",
  },
  "suggestions": {
    "questions_to_ask": [
      {
        "question":
            "क्या आपको निगलने में तकलीफ होती है या खाना अटकता है गले में? (Any difficulty swallowing or food getting stuck?)",
        "rationale":
            "Dysphagia would raise concern for esophageal pathology or malignancy and needs urgent evaluation.",
      },
    ],
    "differentials": [
      {
        "condition": "Peptic Ulcer Disease (PUD)",
        "likelihood": "High",
        "reasoning":
            "History of prior gastric ulcers (छाले), current burning abdominal pain for 5 days, triggered by food, on antacids/pantoprazole. Classic PUD presentation.",
        "icd_code": "K27.9",
      },
      {
        "condition": "H. pylori Infection",
        "likelihood": "High",
        "reasoning":
            "Recurrent peptic ulcers + mouth ulcers + burning epigastric pain strongly suggest H. pylori as underlying cause. Prior treatment history may indicate incomplete eradication.",
        "icd_code": "B96.81",
      },
    ],
    "tests_to_consider": [],
    "red_flags": [],
  },
  "overrides": [],
  "stt_warnings": [],
  "roles_verified": true,
};
