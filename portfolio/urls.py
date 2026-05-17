from django.urls import path
from .views import PortfolioView, BuyStockView, PortfolioSummaryView, PortfolioHoldingsView

urlpatterns = [
    path('', PortfolioView.as_view()),
    path('buy/', BuyStockView.as_view()),
    path('summary/', PortfolioSummaryView.as_view()),
    path('holdings/', PortfolioHoldingsView.as_view()),
]