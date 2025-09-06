from django.urls import path
from . import views
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = ([
    #url
    path('scan_url/', views.scan_url, name='scan_url'),
    path('stats/', views.stats, name='stats'),
    #email
    path("analyze_email/", views.analyze_email, name="analyze_email"),
    path('api/email_stats/', views.email_stats, name='email_stats'),
    #wifi
    path("wifi_scan/", views.wifi_scan, name="wifi_scan"),
    path('alerts/', views.alert_list, name='alert-list'),
])
