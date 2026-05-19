import yfinance as yf
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

class StockChartView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        manual_parameters=[
            openapi.Parameter('period', openapi.IN_QUERY, description="Time period (e.g., '1mo', '1y')", type=openapi.TYPE_STRING),
            openapi.Parameter('interval', openapi.IN_QUERY, description="Data interval (e.g., '1d', '1wk')", type=openapi.TYPE_STRING),
        ]
    )
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
                "52_week_low": float(year_low) if year_low is not None else None,
                "candles": candles
            })
        except Exception as e:
            return Response({"error": str(e)}, status=500)
class Nifty50ListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # A curated list of popular NIFTY 50 / Indian stocks
        popular_stocks = [
            {"symbol": "RELIANCE.NS", "name": "Reliance Industries"},
            {"symbol": "TCS.NS", "name": "Tata Consultancy Services"},
            {"symbol": "HDFCBANK.NS", "name": "HDFC Bank"},
            {"symbol": "INFY.NS", "name": "Infosys"},
            {"symbol": "ICICIBANK.NS", "name": "ICICI Bank"},
            {"symbol": "HINDUNILVR.NS", "name": "Hindustan Unilever"},
            {"symbol": "SBIN.NS", "name": "State Bank of India"},
            {"symbol": "BHARTIARTL.NS", "name": "Bharti Airtel"},
            {"symbol": "ITC.NS", "name": "ITC Limited"},
            {"symbol": "KOTAKBANK.NS", "name": "Kotak Mahindra Bank"},
            {"symbol": "LT.NS", "name": "Larsen & Toubro"},
            {"symbol": "AXISBANK.NS", "name": "Axis Bank"},
            {"symbol": "ASIANPAINT.NS", "name": "Asian Paints"},
            {"symbol": "MARUTI.NS", "name": "Maruti Suzuki"},
            {"symbol": "HCLTECH.NS", "name": "HCL Technologies"}
        ]
        
        # We can also fetch live prices for these if we want, but returning just the list is fast
        return Response(popular_stocks)
