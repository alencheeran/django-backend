from django.db import models
from django.conf import settings


class Trade(models.Model):

    TRADE_TYPES = (
        ('BUY', 'BUY'),
        ('SELL', 'SELL'),
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )

    stock_symbol = models.CharField(
        max_length=10
    )

    quantity = models.IntegerField()

    price = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    trade_type = models.CharField(
        max_length=4,
        choices=TRADE_TYPES
    )

    total_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return f"{self.user.username} - {self.trade_type}"