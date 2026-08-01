"""Emit the plan (JSON on stdout) for the next vocabulary batch.

Picks the next 5 (theme, level) slots, gathers per-category existing words
for dedupe, and surfaces top sentence-coverage gap tokens so a gap-filler
generator can define them as dictionary entries. Advances pipeline state.
"""
import json

import vocab_lib as V

# (theme, category, hint). Each theme is visited at 3 depth levels:
# L1 = most common everyday words, L2 = intermediate, L3 = less common.
THEMES = [
    ("Food & dishes", "Food", "common Thai dishes and food words"),
    ("Fruits & vegetables", "Food", "fruits and vegetables sold in Thailand"),
    ("Cooking & kitchen", "Food", "cooking verbs, methods, kitchen nouns"),
    ("Drinks & café", "Food", "drinks, coffee shop, ordering"),
    ("Herbs & spices", "Food", "Thai herbs, spices, condiments"),
    ("Desserts & snacks", "Food", "Thai desserts, sweets, snacks"),
    ("Rice & noodles", "Food", "rice/noodle types and dishes"),
    ("Taste & texture", "Adjectives", "flavour and texture adjectives"),
    ("Restaurants & ordering", "Food", "eating out, ordering, paying"),
    ("Street food & market", "Shopping", "market stalls, vendors, bargaining"),
    ("Family & relatives", "Family", "kinship terms incl. elder/younger distinctions"),
    ("Friendship & social", "People", "friends, meeting people, socialising"),
    ("Occupations", "People", "jobs and professions"),
    ("Age & life stages", "People", "child, teenager, adult, elderly"),
    ("Emotions & moods", "Feelings", "happy, sad, angry, bored, excited"),
    ("Personality traits", "Adjectives", "kind, lazy, diligent, funny"),
    ("Love & relationships", "Feelings", "dating, marriage, missing someone"),
    ("Body parts", "Body", "body parts head to toe"),
    ("Health & illness", "Health", "symptoms, being sick, recovery"),
    ("Hospital & pharmacy", "Health", "doctor, medicine, treatment"),
    ("Hygiene & bathroom", "Home", "washing, toiletries, bathroom items"),
    ("House & rooms", "Home", "rooms, parts of a house, renting"),
    ("Furniture & household items", "Home", "furniture and everyday objects"),
    ("Kitchen tools", "Home", "utensils, plates, appliances"),
    ("Cleaning & chores", "Home", "housework verbs and tools"),
    ("Clothing", "Clothing", "clothes and wearing verbs"),
    ("Accessories & jewelry", "Clothing", "bags, glasses, gold, accessories"),
    ("Colors & patterns", "Colors", "colours, shades, patterns"),
    ("Weather & seasons", "Nature", "weather, hot/rainy/cool seasons"),
    ("Sky & astronomy", "Nature", "sun, moon, stars, sky"),
    ("Plants & trees", "Nature", "trees, plants, gardening"),
    ("Flowers", "Nature", "flowers incl. lotus, jasmine"),
    ("Water & landscape", "Nature", "river, sea, mountain, island, waterfall"),
    ("Weather extremes", "Nature", "storm, flood, earthquake"),
    ("Animals — pets & farm", "Animals", "pets and farm animals"),
    ("Animals — wild", "Animals", "wild animals incl. elephant, tiger"),
    ("Insects & small creatures", "Animals", "insects, lizards, snails"),
    ("Sea life", "Animals", "fish, shrimp, crab, squid"),
    ("Transport — road", "Travel", "cars, motorbike, tuk-tuk, songthaew, bus"),
    ("Transport — air & rail", "Travel", "plane, train, BTS/MRT"),
    ("Airport & immigration", "Travel", "airport, passport, visa, luggage"),
    ("Driving & traffic", "Travel", "driving, traffic, fuel, parking"),
    ("Directions & navigation", "Directions", "turn, straight, near/far, maps"),
    ("Hotel & accommodation", "Travel", "hotel, booking, room amenities"),
    ("Beach & islands", "Travel", "beach holiday words"),
    ("Massage & spa", "Travel", "Thai massage, spa, relaxation"),
    ("Temple & religion", "Culture", "temple, monk, merit, Buddha"),
    ("Festivals & holidays", "Culture", "Songkran, Loy Krathong, holidays"),
    ("Thai culture & customs", "Culture", "wai, respect, customs"),
    ("Music & dance", "Culture", "music, songs, instruments, dance"),
    ("Sports & exercise", "Sports", "exercise, gym, running, muay thai"),
    ("Games & play", "Sports", "football, games, playing"),
    ("School & education", "School", "school, teacher, homework"),
    ("Reading & writing", "School", "books, letters, writing"),
    ("University & study", "School", "university, exams, subjects"),
    ("Office & work", "Work", "office life, colleagues, tasks"),
    ("Business & trade", "Work", "company, selling, profit"),
    ("Meetings & appointments", "Work", "scheduling, meetings, deadlines"),
    ("Money & banking", "Money", "money, bank, transfer, price words"),
    ("Shopping & bargaining", "Shopping", "buying, discount, sizes, trying on"),
    ("Numbers — large & ordinal", "Numbers", "hundreds+, ordinals, fractions"),
    ("Classifiers", "Grammar", "Thai classifier words with what they count"),
    ("Time — clock & schedule", "Time", "telling time, schedules"),
    ("Days & calendar", "Time", "calendar words, dates, periods"),
    ("Technology & phone", "Technology", "phone, apps, charging, wifi"),
    ("Internet & social media", "Technology", "online life, chat, posting"),
    ("Computers", "Technology", "computer, files, typing"),
    ("Verbs — motion", "Verbs", "go, come, run, enter, exit, fall"),
    ("Verbs — daily routine", "Verbs", "wake, shower, dress, sleep"),
    ("Verbs — communication", "Verbs", "say, tell, ask, answer, call"),
    ("Verbs — cognition & feeling", "Verbs", "think, know, remember, believe"),
    ("Verbs — hands & actions", "Verbs", "hold, pull, push, cut, throw"),
    ("Adjectives — size & shape", "Adjectives", "big, small, long, round"),
    ("Adjectives — quality", "Adjectives", "good, beautiful, new, broken"),
    ("Adverbs & intensity", "Grammar Core", "very, quite, too, almost, already"),
    ("Question words & particles", "Grammar", "question words, polite/mood particles"),
    ("Prepositions & location", "Grammar Core", "in, on, under, beside, between"),
    ("Conjunctions & connectors", "Grammar Core", "and, but, because, so, if"),
    ("Pronouns & address", "Grammar", "pronouns and address terms"),
    ("City & buildings", "Places", "city places and buildings"),
    ("Countryside & farm", "Places", "village, field, farm life"),
    ("Countries & nationalities", "Places", "countries, languages, nationalities"),
    ("Bangkok life", "Places", "Bangkok districts, malls, commuting"),
    ("Emergency & safety", "Safety", "emergencies, warnings, help"),
    ("Police & law", "Safety", "police, rules, fines"),
    ("Government & official", "Society", "official/government words (incl. Sanskrit cognates)"),
    ("News & media", "Society", "news, TV, newspapers"),
    ("Post & delivery", "Communication", "mail, parcels, delivery apps"),
    ("Phone conversation", "Communication", "phone call phrases and verbs"),
    ("Baby & children", "Family", "babies, raising children"),
    ("Celebrations", "Culture", "birthday, wedding, gifts"),
    ("Materials & textures", "Basics", "wood, metal, glass, plastic"),
    ("Shapes & measurements", "Basics", "shapes, weights, measures"),
]
LEVEL_HINTS = {
    1: "the MOST COMMON everyday words a beginner needs first",
    2: "intermediate words a resident/frequent visitor needs (no repeats of the obvious basics)",
    3: "less common but still useful words for fluent daily life (deeper cuts)",
}
THEMES_PER_BATCH = 10


def main():
    state = V.load_state()
    words = V.load_words()
    total = len(words)
    by_cat = {}
    for w in words:
        by_cat.setdefault(w["category"], []).append(f'{w["thai"]} ({w["en"]})')

    slots = []
    cursor = state["theme_cursor"]
    n = len(THEMES)
    for k in range(cursor, cursor + THEMES_PER_BATCH):
        level = k // n + 1
        if level > 3:
            break
        name, cat, hint = THEMES[k % n]
        slots.append({
            "name": name, "category": cat, "level": level,
            "hint": f"{hint} — focus on {LEVEL_HINTS[level]}",
            "existing": by_cat.get(cat, [])[:300],
        })
    if not slots:
        raise SystemExit("theme queue exhausted — extend THEMES in prepare_batch.py")

    gaps = V.coverage_gaps([w["thai"] for w in words], V.load_sentence_thai())
    top_gaps = [t for t, c in gaps.most_common(12) if c >= 2]

    # Short existing words are the raw material for real Thai compounds
    # (น้ำ+ตก=น้ำตก). id order ≈ frequency, so the pool stays beginner-heavy.
    compound_pool = [
        f'{w["thai"]} ({w["en"]})' for w in words
        if len(w["thai"]) <= 5 and " " not in w["thai"]
    ][:300]

    plan = {
        "batch": state["batch"],
        "next_id": max(w["id"] for w in words) + 1,
        "total": total,
        "target": state["target"],
        "words_per_theme": state["words_per_theme"],
        "themes": slots,
        "gap_tokens": top_gaps,
        "compound_pool": compound_pool,
    }
    state["theme_cursor"] = cursor + len(slots)
    state["batch"] += 1
    V.save_state(state)
    out = json.dumps(plan, ensure_ascii=False)
    # Backstop copy so an interrupted run can be resumed without re-planning.
    with open(V.ROOT / "tools" / "batches" / f"plan_{plan['batch']:03d}.json", "w") as f:
        f.write(out)
    print(out)


if __name__ == "__main__":
    main()
