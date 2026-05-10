from django.db import models
from django.conf import settings
from django.db import models
from django.contrib.auth.models import User

class Portfolio(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    stock_name = models.CharField(max_length=100)
    quantity = models.IntegerField()
    buy_price = models.FloatField()

    def __str__(self):
        return self.stock_name


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

    def __str__(self):
        return f"{self.user.username} - {self.stock_symbol}"