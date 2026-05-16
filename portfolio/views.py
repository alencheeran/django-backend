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
            price=price
        )

        serializer = TransactionSerializer(transaction)

        return Response(serializer.data)