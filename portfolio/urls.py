from django.urls import path
from .views import (
    PortfolioView, BuyStockView, PortfolioSummaryView, PortfolioHoldingsView,
    SellStockView, TransactionHistoryView, WatchlistView, WatchlistToggleView, LeaderboardView
)

urlpatterns = [
    path('', PortfolioView.as_view()),
    path('buy/', BuyStockView.as_view()),
    path('summary/', PortfolioSummaryView.as_view()),
    path('holdings/', PortfolioHoldingsView.as_view()),
    path('sell/', SellStockView.as_view()),
    path('transactions/', TransactionHistoryView.as_view()),
    path('watchlist/', WatchlistView.as_view()),
    path('watchlist/toggle/', WatchlistToggleView.as_view()),
    path('leaderboard/', LeaderboardView.as_view()),
]