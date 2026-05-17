from django.urls import path
from .views import StockChartView, Nifty50ListView

urlpatterns = [
    path('nifty50/', Nifty50ListView.as_view(), name='nifty50-list'),
    path('<str:symbol>/chart/', StockChartView.as_view(), name='stock-chart'),
]
