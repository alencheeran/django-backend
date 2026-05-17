from django.db import models
from django.conf import settings


class Portfolio(models.Model):

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )

    stock_symbol = models.CharField(
        max_length=10
    )

    quantity = models.IntegerField(
        default=0
    )

    avg_price = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    realized_profit = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=0.00
    )

    last_updated = models.DateTimeField(
        auto_now=True
    )

    def __str__(self):
        return f"{self.user.username} - {self.stock_symbol}"


class Transaction(models.Model):

    TRANSACTION_TYPES = (
        ('BUY', 'Buy'),
        ('SELL', 'Sell'),
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )

    stock_symbol = models.CharField(
        max_length=10
    )

    transaction_type = models.CharField(
        max_length=4,
        choices=TRANSACTION_TYPES
    )

    quantity = models.IntegerField()

    price = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    total_value = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        null=True,
        blank=True
    )

    status = models.CharField(
        max_length=20,
        default='COMPLETED'
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return f"{self.user.username} - {self.transaction_type}"