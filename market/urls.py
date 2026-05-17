from django.urls import path
from .views import StockChartView

urlpatterns = [
    path('<str:symbol>/chart/', StockChartView.as_view(), name='stock-chart'),
]
