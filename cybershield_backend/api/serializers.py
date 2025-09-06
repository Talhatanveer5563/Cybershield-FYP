from rest_framework import serializers
from .models import Alert  # Import your Alert model
from .models import EmailAnalysis

class AlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alert
        fields = ['ip', 'mac', 'timestamp']

class EmailAnalysisSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailAnalysis
        fields = '__all__'