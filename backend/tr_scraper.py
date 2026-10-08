from playwright.sync_api import sync_playwright
from rapidfuzz import fuzz

def fetch_tr_legal_odds():
    tr_matches = []
    print("[TARAYICI] Nesine.com bülteni taranıyor...")

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
                                #Sadece Futbol (TYPE = 1) maçlarını al, diğerlerini (Basketbol vb.) atla
                                event_type = item.get("TYPE") or item.get("type")
                                if str(event_type) != "1":
                                    continue
                                    
                                home = item.get("HN") or item.get("hn")
                                away = item.get("AN") or item.get("an")
                                league = item.get("LN") or item.get("L") or f"Lig {item.get('C', '')}"
                                time = item.get("T") or item.get("t") or ""
                                date = item.get("D") or item.get("d") or ""
                                
                                match_markets = {}
                                
                                # Hedeflenen bahis marketleri ID'leri
                                mtid_map = {
                                    1: "Maç Sonucu", 99: "Maç Sonucu", 115: "Maç Sonucu",
                                    3: "İlk Yarı Sonucu",
                                    13: "1.5 Gol Alt/Üst",
                                    14: "2.5 Gol Alt/Üst",
                                    15: "3.5 Gol Alt/Üst",
                                    22: "Karşılıklı Gol"
                                }
                                
                                markets = item.get("MA", []) or item.get("m", [])
                                for m in markets:
                                    mtid = m.get("MTID") or m.get("t")
                                    market_name = m.get("MN") or mtid_map.get(mtid)
                                    
                                    if market_name:
                                        outcomes = m.get("OCA", []) or m.get("o", [])
                                        odds = {}
                                        for o in outcomes:
                                            name = str(o.get("N") or o.get("n"))
                                            odd = o.get("O") or o.get("v")
                                            if odd:
                                                # Alt/Üst - Var/Yok İsimlendirmeleri
                                                if "Alt" in market_name or "Üst" in market_name:
                                                    if name == "1": name = "Alt"
                                                    elif name == "2": name = "Üst"
                                                elif market_name == "Karşılıklı Gol":
                                                    if name == "1": name = "Var"
                                                    elif name == "2": name = "Yok"
                                                    
                                                odds[name] = float(odd)
                                                
                                        if odds:
                                            match_markets[market_name] = odds
                                            
                                if home and away and match_markets:
                                    tr_matches.append({
                                        "home_team": home, 
                                        "away_team": away, 
                                        "league": str(league),
                                        "time": time,
                                        "date": date,
                                        "markets": match_markets
                                    })
                        except Exception:
                            pass

            page.on("response", handle_response)
            page.goto("https://www.nesine.com/iddaa", timeout=45000, wait_until="domcontentloaded")
            page.wait_for_timeout(4000)
            
            try:
                close_btn_selector = "button:has(i.nsn-i-cancel-b)"
                page.locator(close_btn_selector).click(timeout=5000)
            except:
                pass
            
            page.wait_for_timeout(6000)
            browser.close()
            
        except Exception as e:
            print(f"[TARAYICI HATA] {e}")

    # Aynı maçın mükerrer listelenmesini önle
    unique_matches = {f"{m['home_team']}-{m['away_team']}": m for m in tr_matches}
    return list(unique_matches.values())