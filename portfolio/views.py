from decimal import Decimal

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models import Portfolio, Transaction
from .serializers import PortfolioSerializer
from .transaction_serializer import TransactionSerializer


class PortfolioView(APIView):

    permission_classes = [IsAuthenticated]

    def get(self, request):

        portfolios = Portfolio.objects.filter(user=request.user)

        serializer = PortfolioSerializer(portfolios, many=True)

        return Response(serializer.data)


class BuyStockView(APIView):

    permission_classes = [IsAuthenticated]

    def post(self, request):

        stock_symbol = request.data.get('stock_symbol')
        quantity = int(request.data.get('quantity'))
        price = Decimal(request.data.get('price'))

        total_cost = quantity * price

        user = request.user

        if user.balance < total_cost:

            return Response({
                "error": "Insufficient balance"
            }, status=400)

        user.balance -= total_cost
        user.save()

        portfolio, created = Portfolio.objects.get_or_create(
            user=user,
            stock_symbol=stock_symbol,
            defaults={
                'quantity': quantity,
                'avg_price': price
            }
        )

        if not created:

            total_quantity = portfolio.quantity + quantity

            new_avg_price = (
                (
                    portfolio.quantity * portfolio.avg_price
                ) +
                (
                    quantity * price
                )
            ) / total_quantity

            portfolio.quantity = total_quantity
            portfolio.avg_price = new_avg_price
            portfolio.save()

        transaction = Transaction.objects.create(
            user=user,
            stock_symbol=stock_symbol,
            transaction_type='BUY',
            quantity=quantity,
            price=price,
            total_value=total_cost,
            status='COMPLETED'
        )

        serializer = TransactionSerializer(transaction)

        return Response(serializer.data)

import yfinance as yf

class PortfolioHoldingsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        portfolios = Portfolio.objects.filter(user=request.user)
        holdings = []
        
        for p in portfolios:
            if p.quantity == 0:
                continue
            
            symbol = p.stock_symbol
            ticker_symbol = f"{symbol}.NS" if not symbol.endswith(".NS") else symbol
            
            try:
                ticker = yf.Ticker(ticker_symbol)
                # Extra data defaults
                today_high = None
                today_low = None
                volume = None
                year_high = None
                year_low = None
                
                # Fallback to previous close or history if fast_info fails
                try:
                    current_price = ticker.fast_info['lastPrice']
                    today_high = ticker.fast_info.get('dayHigh')
                    today_low = ticker.fast_info.get('dayLow')
                    volume = ticker.fast_info.get('lastVolume')
                    year_high = ticker.fast_info.get('yearHigh')
                    year_low = ticker.fast_info.get('yearLow')
                except Exception:
                    hist = ticker.history(period="1d")
                    current_price = hist['Close'].iloc[-1] if not hist.empty else float(p.avg_price)
            except Exception:
                current_price = float(p.avg_price)
                today_high = None
                today_low = None
                volume = None
                year_high = None
                year_low = None
                
            current_price = Decimal(str(current_price))
            current_value = p.quantity * current_price
            invested_value = p.quantity * p.avg_price
            profit_loss = current_value - invested_value
            profit_loss_pct = (profit_loss / invested_value * 100) if invested_value > 0 else Decimal(0)
            
            holdings.append({
                "stock_symbol": symbol,
                "quantity": p.quantity,
                "average_buy_price": float(p.avg_price),
                "current_price": float(current_price),
                "current_value": float(current_value),
                "profit_loss": float(profit_loss),
                "profit_loss_percentage": float(profit_loss_pct),
                "today_high": float(today_high) if today_high is not None else None,
                "today_low": float(today_low) if today_low is not None else None,
                "volume": int(volume) if volume is not None else None,
                "52_week_high": float(year_high) if year_high is not None else None,
                "52_week_low": float(year_low) if year_low is not None else None,
            })
            
        return Response(holdings)

class PortfolioSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        portfolios = Portfolio.objects.filter(user=user)
        
        available_cash = user.balance
        invested_amount = Decimal(0)
        total_current_value = Decimal(0)
        
        previous_close_value = Decimal(0)
        
        for p in portfolios:
            if p.quantity == 0:
                continue
                
            symbol = p.stock_symbol
            ticker_symbol = f"{symbol}.NS" if not symbol.endswith(".NS") else symbol
            
            try:
                ticker = yf.Ticker(ticker_symbol)
                try:
                    current_price = Decimal(str(ticker.fast_info['lastPrice']))
                    prev_close = Decimal(str(ticker.fast_info['previousClose']))
                except Exception:
                    hist = ticker.history(period="5d")
                    if not hist.empty and len(hist) >= 2:
                        current_price = Decimal(str(hist['Close'].iloc[-1]))
                        prev_close = Decimal(str(hist['Close'].iloc[-2]))
                    else:
                        current_price = p.avg_price
                        prev_close = p.avg_price
            except Exception:
                current_price = p.avg_price
                prev_close = p.avg_price
                
            current_value = p.quantity * current_price
            invested_value = p.quantity * p.avg_price
            
            total_current_value += current_value
            invested_amount += invested_value
            
            previous_close_value += p.quantity * prev_close
            
        portfolio_value = available_cash + total_current_value
        
        # User initial virtual capital from user model
        initial_virtual_capital = user.initial_balance
        total_return = portfolio_value - initial_virtual_capital
        total_return_percentage = (total_return / initial_virtual_capital * 100) if initial_virtual_capital > 0 else Decimal(0)
        
        one_day_return = total_current_value - previous_close_value
        one_day_return_pct = (one_day_return / previous_close_value * 100) if previous_close_value > 0 else Decimal(0)
        
        return Response({
            "total_portfolio_value": float(portfolio_value),
            "available_cash": float(available_cash),
            "invested_amount": float(invested_amount),
            "one_day_return": float(one_day_return),
            "one_day_return_percentage": float(one_day_return_pct),
            "total_return": float(total_return),
            "total_return_percentage": float(total_return_percentage)
        })