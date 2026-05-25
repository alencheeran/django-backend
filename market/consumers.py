import asyncio
import random
from channels.generic.websocket import AsyncJsonWebsocketConsumer

POPULAR_STOCKS = {
    "RELIANCE.NS": {"name": "Reliance Industries", "price": 2450.0, "baseline": 2450.0},
    "TCS.NS": {"name": "Tata Consultancy Services", "price": 3400.0, "baseline": 3400.0},
    "HDFCBANK.NS": {"name": "HDFC Bank", "price": 1600.0, "baseline": 1600.0},
    "INFY.NS": {"name": "Infosys", "price": 1450.0, "baseline": 1450.0},
    "ICICIBANK.NS": {"name": "ICICI Bank", "price": 950.0, "baseline": 950.0},
    "HINDUNILVR.NS": {"name": "Hindustan Unilever", "price": 2500.0, "baseline": 2500.0},
    "SBIN.NS": {"name": "State Bank of India", "price": 580.0, "baseline": 580.0},
    "BHARTIARTL.NS": {"name": "Bharti Airtel", "price": 850.0, "baseline": 850.0},
    "ITC.NS": {"name": "ITC Limited", "price": 440.0, "baseline": 440.0},
    "KOTAKBANK.NS": {"name": "Kotak Mahindra Bank", "price": 1850.0, "baseline": 1850.0},
    "LT.NS": {"name": "Larsen & Toubro", "price": 2350.0, "baseline": 2350.0},
    "AXISBANK.NS": {"name": "Axis Bank", "price": 960.0, "baseline": 960.0},
    "ASIANPAINT.NS": {"name": "Asian Paints", "price": 3100.0, "baseline": 3100.0},
    "MARUTI.NS": {"name": "Maruti Suzuki", "price": 9500.0, "baseline": 9500.0},
    "HCLTECH.NS": {"name": "HCL Technologies", "price": 1150.0, "baseline": 1150.0}
}

class StockPriceConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        # Initialize instance variables
        self.subscribed_symbols = set()
        self.prices_cache = {}
        self.stream_task = None
        
        # Accept connection
        await self.accept()

    async def disconnect(self, close_code):
        # Cancel streaming task if running
        if self.stream_task and not self.stream_task.done():
            self.stream_task.cancel()

    async def receive_json(self, content):
        action = content.get('action')
        symbols = content.get('symbols', [])
        
        if not action:
            await self.send_json({"error": "Missing 'action' field. Expecting 'subscribe' or 'unsubscribe'."})
            return

        # Ensure symbols is a list and normalized to uppercase
        if isinstance(symbols, str):
            symbols = [symbols]
        normalized_symbols = [sym.upper() for sym in symbols]

        if action == 'subscribe':
            for sym in normalized_symbols:
                # Add .NS extension if not present and matches popular symbols in uppercase
                if not sym.endswith(".NS") and f"{sym}.NS" in POPULAR_STOCKS:
                    sym = f"{sym}.NS"
                self.subscribed_symbols.add(sym)
                
                # Initialize price cache for this symbol if not present
                if sym not in self.prices_cache:
                    if sym in POPULAR_STOCKS:
                        self.prices_cache[sym] = {
                            "price": POPULAR_STOCKS[sym]["price"],
                            "baseline": POPULAR_STOCKS[sym]["baseline"]
                        }
                    else:
                        base = random.uniform(100.0, 1000.0)
                        self.prices_cache[sym] = {
                            "price": base,
                            "baseline": base
                        }

            await self.send_json({
                "status": "subscribed",
                "current_subscriptions": list(self.subscribed_symbols)
            })

            # Start streaming loop if not already running
            if not self.stream_task or self.stream_task.done():
                self.stream_task = asyncio.create_task(self.stream_prices_loop())

        elif action == 'unsubscribe':
            for sym in normalized_symbols:
                if sym in self.subscribed_symbols:
                    self.subscribed_symbols.remove(sym)
                elif f"{sym}.NS" in self.subscribed_symbols:
                    self.subscribed_symbols.remove(f"{sym}.NS")

            await self.send_json({
                "status": "unsubscribed",
                "current_subscriptions": list(self.subscribed_symbols)
            })
        else:
            await self.send_json({"error": f"Unknown action '{action}'"})

    async def stream_prices_loop(self):
        try:
            while True:
                if not self.subscribed_symbols:
                    await asyncio.sleep(0.5)
                    continue

                updates = []
                for sym in list(self.subscribed_symbols):
                    cache_item = self.prices_cache[sym]
                    
                    # Random price walk: change between -0.15% and +0.15%
                    percent_change = random.uniform(-0.0015, 0.0015)
                    new_price = cache_item["price"] * (1 + percent_change)
                    cache_item["price"] = new_price
                    
                    change = new_price - cache_item["baseline"]
                    change_pct = (change / cache_item["baseline"]) * 100
                    
                    updates.append({
                        "symbol": sym,
                        "price": round(new_price, 2),
                        "change": round(change, 2),
                        "change_percentage": round(change_pct, 2)
                    })

                # Broadcast live updates to this connection
                await self.send_json({
                    "type": "stock_update",
                    "stocks": updates
                })
                
                # Stream once per second
                await asyncio.sleep(1.0)
        except asyncio.CancelledError:
            pass
