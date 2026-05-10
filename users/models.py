from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    balance = models.DecimalField(max_digits=15, decimal_places=2, default=100000)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.username
