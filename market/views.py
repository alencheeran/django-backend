import yfinance as yf
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

class StockChartView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, symbol):
        period = request.query_params.get('period', '1mo')
        interval = request.query_params.get('interval', '1d')

        ticker_symbol = f"{symbol}.NS" if not symbol.endswith(".NS") else symbol
        
        try:
            ticker = yf.Ticker(ticker_symbol)
            hist = ticker.history(period=period, interval=interval)
            
            if hist.empty:
                return Response({"error": "No data found for symbol"}, status=404)
            
            # Try to get current price and extra info, fallback to last close price
            try:
                current_price = ticker.fast_info['lastPrice']
                today_high = ticker.fast_info.get('dayHigh')
                today_low = ticker.fast_info.get('dayLow')
                volume = ticker.fast_info.get('lastVolume')
                year_high = ticker.fast_info.get('yearHigh')
                year_low = ticker.fast_info.get('yearLow')
            except Exception:
                current_price = hist['Close'].iloc[-1]
                today_high = hist['High'].iloc[-1]
                today_low = hist['Low'].iloc[-1]
                volume = hist['Volume'].iloc[-1]
                year_high = None
                year_low = None
            
            candles = []
            for date, row in hist.iterrows():
                candles.append({
                    "date": date.isoformat() if hasattr(date, 'isoformat') else str(date),
                    "open": float(row['Open']),
                    "high": float(row['High']),
                    "low": float(row['Low']),
                    "close": float(row['Close']),
                    "volume": int(row['Volume']),
                })
                
            return Response({
                "symbol": symbol,
                "current_price": float(current_price),
                "today_high": float(today_high) if today_high is not None else None,
                "today_low": float(today_low) if today_low is not None else None,
                "volume": int(volume) if volume is not None else None,
                "52_week_high": float(year_high) if year_high is not None else None,
                "52_week_low": float(year_low) if year_low is not None else None,
                "candles": candles
            })
        except Exception as e:
            return Response({"error": str(e)}, status=500)
