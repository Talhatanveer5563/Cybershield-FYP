from django.db import models
from rest_framework import serializers


#alert
class Alert(models.Model):
    title = models.CharField(max_length=100)
    message = models.TextField()
    level = models.CharField(max_length=20)  # e.g. info, warning, danger
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title


#url
class URLScan(models.Model):
    url = models.URLField()
    result = models.CharField(max_length=100)  # e.g., "Safe" or "Phishing"
    scanned_at = models.DateTimeField(auto_now_add=True)
    is_dangerous = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.url} - {self.result}"

class ScannedURL(models.Model):
    url = models.URLField()
    is_dangerous = models.BooleanField(default=False)
    scanned_at = models.DateTimeField(auto_now_add=True)
    domain = models.CharField(max_length=255, default='', blank=True)

class URLScanSerializer(serializers.ModelSerializer):
    class Meta:
        model = URLScan
        fields = '__all__'

class KnownDevice(models.Model):
    mac_address = models.CharField(
        max_length=17,
        unique=True,
        help_text="MAC address in the format XX:XX:XX:XX:XX:XX"
    )
    device_name = models.CharField(
        max_length=100,
        blank=True,
        help_text="Optional human-friendly name for this device"
    )
    added_on = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.mac_address} ({self.device_name or 'Unnamed'})"

class IntrusionAlert(models.Model):
    ip = models.GenericIPAddressField()
    mac = models.CharField(max_length=20)
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.ip} - {self.mac}"


class EmailAnalysis(models.Model):
    content = models.TextField()
    is_phishing = models.BooleanField()
    phishing_score = models.IntegerField(default=0)
    suspicious_keywords = models.JSONField(default=list)
    links = models.JSONField(default=list)
    suspicious_domains = models.JSONField(default=list)
    html_elements = models.JSONField(default=list)
    sender_reputation = models.CharField(max_length=50)
    analysis_summary = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)