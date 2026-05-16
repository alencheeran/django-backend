from django.urls import path
from .views import PortfolioView, BuyStockView

urlpatterns = [
    path('', PortfolioView.as_view()),
    path('buy/', BuyStockView.as_view()),
]