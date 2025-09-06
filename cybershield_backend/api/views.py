from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
import requests
import re
import subprocess
from urllib.parse import urlparse
from datetime import datetime
from .models import KnownDevice, Alert, URLScan, ScannedURL
from .serializers import AlertSerializer
from .models import EmailAnalysis
from .serializers import EmailAnalysisSerializer
from rest_framework import status

# ============================
# WIFI SCAN (no Scapy needed)
# ============================
@api_view(['GET'])
def wifi_scan(request):
    """
    Scans the local network by reading the ARP table (arp -a).
    Returns a list of {"ip": "...", "mac": "...", "known": True/False}.
    """

    try:
        # Run 'arp -a' (works on Windows) to get ARP cache
        output = subprocess.check_output("arp -a", shell=True, text=True)

        # Load all known MACs from your database
        known_macs = set(KnownDevice.objects.values_list('mac_address', flat=True))

        devices = []
        for line in output.splitlines():
            # Parse lines like: "  192.168.0.2          00-0a-95-9d-68-16     dynamic"
            match = re.search(
                r"(\d+\.\d+\.\d+\.\d+)\s+([0-9A-Fa-f]{2}(?:-[0-9A-Fa-f]{2}){5})",
                line
            )
            if match:
                ip_addr = match.group(1)
                mac_addr = match.group(2).replace('-', ':').lower()
                devices.append({
                    "ip": ip_addr,
                    "mac": mac_addr,
                    "known": (mac_addr in known_macs)
                })

        return Response({"devices": devices})

    except subprocess.CalledProcessError:
        return Response(
            {"error": "Failed to read ARP cache."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    except Exception as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# ============================
# URL SCAN
# ============================

@csrf_exempt
def scan_url(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Invalid request method.'}, status=405)
    try:
        data = json.loads(request.body)
        url = data.get('url') or ''
        if not url:
            return JsonResponse({"error": "URL is required."}, status=400)

        # Simple phishing logic
        phishing_keywords = ['login', 'verify', 'secure', 'update', 'account', 'password']
        is_dangerous = any(kw in url.lower() for kw in phishing_keywords)
        result = "Dangerous" if is_dangerous else "Safe"

        # Get domain info
        domain_info = get_domain_info(url)

        # Save scan record
        scan = ScannedURL.objects.create(
            url=url,
            is_dangerous=is_dangerous,
            scanned_at=datetime.now(),
            domain=domain_info.get("domain", "")
        )

        return JsonResponse({
            "scan_id": scan.id,
            "result": result,
            "domain_info": domain_info,
            "scanned_at": scan.scanned_at.isoformat()
        }, status=200)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=400)
def get_domain_info(url):
    parsed = urlparse(url)
    domain = parsed.netloc
    try:
        resp = requests.get(f"https://api.domainsdb.info/v1/domains/search?domain={domain}", timeout=5)
        data = resp.json()
        domains = data.get("domains")

        if not domains:
            return {"domain": domain, "error": "No domain data found"}

        info = domains[0]
        return {
            "domain": domain,
            "create_date": info.get("create_date", "N/A"),
            "update_date": info.get("update_date", "N/A"),
            "country": info.get("country", "N/A"),
            "isDead": info.get("isDead", "N/A"),
            "ip": info.get("A", ["N/A"])[0] if info.get("A") else "N/A"
        }
    except Exception as e:
        print(f"[Error fetching domain info]: {e}")
        return {"domain": domain, "error": "Could not fetch info"}

@api_view(['GET'])
def stats(request):
    total = ScannedURL.objects.count()
    dangerous = ScannedURL.objects.filter(is_dangerous=True).count()
    safe = total - dangerous

    recent = ScannedURL.objects.order_by('-scanned_at')[:10]
    history = [
        {
            "url": i.url,
            "result": "Dangerous" if i.is_dangerous else "Safe",
            "scanned_at": i.scanned_at.isoformat(),
            "domain": i.domain
        }
        for i in recent
    ]

    return Response({
        "summary": {"total": total, "dangerous": dangerous, "safe": safe},
        "recent_scans": history
    })
PHISHING_KEYWORDS = [
    'urgent', 'account suspended', 'click here',
    'verify', 'update your information'
]

@api_view(['POST'])
def analyze_email(request):
    content = request.data.get('content', '').strip()
    if not content:
        return Response({"error": "No email content provided."},
                        status=status.HTTP_400_BAD_REQUEST)

    found = [kw for kw in PHISHING_KEYWORDS if kw.lower() in content.lower()]
    links = re.findall(r'(https?://\S+)', content)
    is_phishing = len(found) >= 2 or bool(links)
    sender_reputation = "Low" if is_phishing else "High"
    analysis_summary = (
        "The email contains multiple phishing indicators including suspicious links and common phishing keywords."
        if is_phishing else "The email appears to be safe."
    )

    # Extend as needed: suspicious_domains, html_elements, etc.
    suspicious_domains = []
    html_elements = []

    record = EmailAnalysis.objects.create(
        content=content,
        is_phishing=is_phishing,
        phishing_score=len(found),
        suspicious_keywords=found,
        links=links,
        suspicious_domains=suspicious_domains,
        html_elements=html_elements,
        sender_reputation=sender_reputation,
        analysis_summary=analysis_summary
    )

    return Response(EmailAnalysisSerializer(record).data, status=status.HTTP_200_OK)


@api_view(['GET'])
def email_stats(request):
    total = EmailAnalysis.objects.count()
    phish = EmailAnalysis.objects.filter(is_phishing=True).count()
    safe = total - phish

    keyword_counts = {}
    for rec in EmailAnalysis.objects.all():
        for kw in rec.suspicious_keywords:
            keyword_counts[kw] = keyword_counts.get(kw, 0) + 1

    top = sorted(keyword_counts.items(), key=lambda x: x[1], reverse=True)[:5]

    return Response({
        "total_emails": total,
        "phishing_emails": phish,
        "safe_emails": safe,
        "top_suspicious_keywords": top
    }, status=status.HTTP_200_OK)

# ============================
# ALERT LIST
# ============================
@api_view(['GET'])
def alert_list(request):
    alerts = Alert.objects.all().order_by('-timestamp')
    serializer = AlertSerializer(alerts, many=True)
    return Response(serializer.data)
