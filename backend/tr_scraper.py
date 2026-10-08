from playwright.sync_api import sync_playwright
from rapidfuzz import fuzz

def fetch_tr_legal_odds():
    tr_matches = []
    print("[TARAYICI] Nesine.com açılıyor, güncel JSON yapısı çözümleniyor...")

    with sync_playwright() as p:
        try:
            browser = p.chromium.launch(channel="chrome", headless=False)
            context = browser.new_context(
                user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                viewport={'width': 1920, 'height': 1080}
            )
            
            page = context.new_page()
            page.add_init_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")

            def handle_response(response):
                if response.request.resource_type in ["xhr", "fetch"]:
                    url = response.url.lower()
                    if "getlivebultenv3" in url or "getprebultenfull" in url:
                        try:
                            data = response.json()
                            events = data.get("sg", {}).get("EA", []) or data.get("sg", {}).get("ea", [])
                            
                            for item in events:
                                home = item.get("HN") or item.get("hn")
                                away = item.get("AN") or item.get("an")
                                odds = {}
                                
                                # Yeni API yapısındaki Marketler dizisi (MA)
                                markets = item.get("MA", [])
                                for m in markets:
                                    # MTID 1: Futbol MS, MTID 115: Basketbol MS
                                    if m.get("MTID") in [1, 115, 99]: 
                                        # Oranlar dizisi (OCA)
                                        outcomes = m.get("OCA", [])
                                        for o in outcomes:
                                            # N: Seçenek (1, X, 2), O: Oran
                                            name = str(o.get("N"))
                                            odd = o.get("O")
                                            if odd:
                                                odds[name] = float(odd)
                                                
                                if home and away and odds:
                                    tr_matches.append({"home_team": home, "away_team": away, "odds": odds})
                        except Exception:
                            pass

            page.on("response", handle_response)

            print("[TARAYICI] Nesine bülten sayfasına gidiliyor...")
            page.goto("https://www.nesine.com/iddaa", timeout=45000, wait_until="domcontentloaded")
            
            page.wait_for_timeout(4000)
            
            try:
                close_btn_selector = "button:has(i.nsn-i-cancel-b)"
                page.locator(close_btn_selector).click(timeout=5000)
            except:
                pass
            
            print("[TARAYICI] Bültenlerin tamamen işlenmesi için bekleniyor (8 saniye)...")
            page.wait_for_timeout(8000)
            
            browser.close()
            
        except Exception as e:
            print(f"[TARAYICI HATA] {e}")

    # Mükerrer maçları temizle
    unique_matches = {f"{m['home_team']}-{m['away_team']}": m for m in tr_matches}
    return list(unique_matches.values())

def match_tr_teams(global_home, global_away, tr_matches_list):
    best_match = None
    highest_score = 0
    global_str = f"{global_home} {global_away}".lower()

    for tr_m in tr_matches_list:
        tr_str = f"{tr_m['home_team']} {tr_m['away_team']}".lower()
        score = fuzz.token_set_ratio(global_str, tr_str)
        if score > 60 and score > highest_score:
            highest_score = score
            best_match = tr_m

    return best_match

if __name__ == "__main__":
    matches = fetch_tr_legal_odds()
    print(f"\n[SONUÇ] Toplam Çekilen Maç Sayısı: {len(matches)}")
    if matches:
        print("\nÖrnek Çekilen Maç:")
        print(matches[0])