from rest_framework.views import APIView
from rest_framework.response import Response


class PortfolioView(APIView):

    def get(self, request):
        return Response({
            "message": "Portfolio API working"
        })