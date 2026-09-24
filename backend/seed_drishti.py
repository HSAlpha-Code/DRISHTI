import os
import sys
import django
import hashlib
import json
from datetime import date, datetime, timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sih_backend.settings')
django.setup()

from centers.models import (
    NGOOrganization, Project, Funding, Expense, Beneficiary, 
    Document, Camera, AlertEvent, IssueReport, ProgressReport, InstituteCenter
)
from inspections.models import Inspection, AuditLog, AuditTask

def seed_all():
    print("Clearing previous Drishti mock data...")
    Document.objects.all().delete()
    Expense.objects.all().delete()
    Funding.objects.all().delete()
    Beneficiary.objects.all().delete()
    Camera.objects.all().delete()
    AlertEvent.objects.all().delete()
    IssueReport.objects.all().delete()
    ProgressReport.objects.all().delete()
    Inspection.objects.all().delete()
    AuditLog.objects.all().delete()
    Project.objects.all().delete()
    NGOOrganization.objects.all().delete()

    print("Seeding NGOs...")
    ngos_data = [
        {
            "name": "Akshaya Vidya Foundation",
            "registration_id": "AKSH1-78923-DEL01-99824-MOSJE",
            "sector": "Education",
            "city": "New Delhi",
            "state": "Delhi",
            "full_address": "Plot 14, Institutional Area, Dwarka Sector 10, New Delhi 110075",
            "contact_email": "director@akshayavidya.org.in",
            "contact_phone": "+91 11 2808 4401",
            "verification_status": "Verified",
            "services_provided": ["Skill Training", "Vocational Education", "Digital Lab Access", "Special Needs Support"],
            "scope_and_facilities": ["Classrooms", "Computer Lab", "Library", "Ramp Access", "CCTV Monitoring"],
            "latitude": 28.5921,
            "longitude": 77.0460
        },
        {
            "name": "Samarpan Seva Samiti",
            "registration_id": "SAMP2-89104-MUM02-44102-MOSJE",
            "sector": "Healthcare",
            "city": "Mumbai",
            "state": "Maharashtra",
            "full_address": "88/B, Swami Vivekananda Road, Bandra East, Mumbai 400051",
            "contact_email": "admin@samarpanseva.org",
            "contact_phone": "+91 22 2642 8820",
            "verification_status": "Verified",
            "services_provided": ["Primary Health Care", "Physiotherapy", "Elderly Care Day Wing", "Nutritional Supplementation"],
            "scope_and_facilities": ["Medical Consultation Room", "Physiotherapy Ward", "Pharmacy", "Wheelchair Facilities"],
            "latitude": 19.0596,
            "longitude": 72.8406
        },
        {
            "name": "Pragati Gramin Vikas Trust",
            "registration_id": "PRAG3-44192-BLR03-77218-MOSJE",
            "sector": "Rural Development",
            "city": "Bengaluru",
            "state": "Karnataka",
            "full_address": "52, 1st Cross, Indira Nagar 2nd Stage, Bengaluru 560038",
            "contact_email": "contact@pragatitrust.org",
            "contact_phone": "+91 80 2521 9901",
            "verification_status": "Verified",
            "services_provided": ["Artisan Capacity Building", "Handicrafts Training", "Solar Energy Literacy", "Micro-Credit Orientation"],
            "scope_and_facilities": ["Workshop Shed", "Training Hall", "Resource Center", "Storage Unit"],
            "latitude": 12.9784,
            "longitude": 77.6408
        },
        {
            "name": "Chetna Mahila Kalyan Parishad",
            "registration_id": "CHET4-66231-LKO04-33190-MOSJE",
            "sector": "Women Welfare",
            "city": "Lucknow",
            "state": "Uttar Pradesh",
            "full_address": "B-12, Gomti Nagar Sector 4, Lucknow 226010",
            "contact_email": "info@chetnamahila.org",
            "contact_phone": "+91 522 2398 120",
            "verification_status": "Verified",
            "services_provided": ["Women Legal Aid", "Self-Help Group Incubation", "Tailoring Certification", "Counseling"],
            "scope_and_facilities": ["Counseling Chambers", "Stitching Training Unit", "Creche Room"],
            "latitude": 26.8467,
            "longitude": 80.9462
        },
        {
            "name": "Arogya Drishti Mission",
            "registration_id": "AROG5-55190-JAI05-88301-MOSJE",
            "sector": "Healthcare",
            "city": "Jaipur",
            "state": "Rajasthan",
            "full_address": "C-41, Malviya Nagar Industrial Area, Jaipur 302017",
            "contact_email": "secretary@arogyadrishti.org",
            "contact_phone": "+91 141 2750 334",
            "verification_status": "Verified",
            "services_provided": ["Cataract Screening", "Free Optical Dispensary", "Assistive Eye Care Devices", "School Vision Screening"],
            "scope_and_facilities": ["Optometry Suite", "Sterilized Procedure Room", "Waiting Hall"],
            "latitude": 26.9124,
            "longitude": 75.7873
        },
        {
            "name": "Sahayata Divyangjan Sansthan",
            "registration_id": "SAHA6-11928-HYD06-22894-MOSJE",
            "sector": "Disability Support",
            "city": "Hyderabad",
            "state": "Telangana",
            "full_address": "7-1-29, Ameerpet Main Road, Hyderabad 500016",
            "contact_email": "support@sahayatatrust.org",
            "contact_phone": "+91 40 2374 8190",
            "verification_status": "Under Review",
            "services_provided": ["Prosthetics Fitment", "Speech Therapy", "Braille Training", "Mobility Orientation"],
            "scope_and_facilities": ["Prosthetics Workshop", "Audio-Speech Room", "Barrier-Free Toilets"],
            "latitude": 17.3850,
            "longitude": 78.4867
        }
    ]

    ngo_objs = {}
    for nd in ngos_data:
        org = NGOOrganization.objects.create(**nd)
        ngo_objs[org.name] = org

    print(f"Created {len(ngo_objs)} NGOs.")

    # Seeding Projects
    projects_data = [
        {
            "organization": ngo_objs["Akshaya Vidya Foundation"],
            "project_id": "PRJ-DEL-2025-01",
            "name": "PM-DAKSH Divyangjan Skill Center",
            "category": "Vocational Empowerment",
            "status": "Active",
            "start_date": date(2025, 4, 1),
            "end_date": date(2026, 3, 31),
            "description": "Comprehensive market-aligned vocational training in data entry, assist-tech operation, and digital services for 150 persons with disabilities under PM-DAKSH.",
            "sanctioned_amount": 4500000.0,
            "released_amount": 3200000.0,
            "spent_amount": 2640000.0,
            "beneficiaries_target": 150,
            "beneficiaries_registered": 142,
            "progress_pct": 78.0
        },
        {
            "organization": ngo_objs["Akshaya Vidya Foundation"],
            "project_id": "PRJ-DEL-2025-02",
            "name": "Senior Citizens Daycare & Medical Wing",
            "category": "Geriatric Welfare",
            "status": "Active",
            "start_date": date(2025, 6, 15),
            "end_date": date(2026, 6, 14),
            "description": "Providing daytime respite, cognitive recreation, and routine health checks for vulnerable elders in South West Delhi.",
            "sanctioned_amount": 2800000.0,
            "released_amount": 1900000.0,
            "spent_amount": 1450000.0,
            "beneficiaries_target": 90,
            "beneficiaries_registered": 84,
            "progress_pct": 65.0
        },
        {
            "organization": ngo_objs["Samarpan Seva Samiti"],
            "project_id": "PRJ-MUM-2025-01",
            "name": "De-addiction & Psychosocial Rehabilitation Center",
            "category": "Substance Abuse Prevention",
            "status": "Active",
            "start_date": date(2025, 1, 10),
            "end_date": date(2025, 12, 31),
            "description": "Inpatient and community outpatient detoxification, psychological counseling, and occupational rehabilitation under NAPDDR scheme.",
            "sanctioned_amount": 5200000.0,
            "released_amount": 4100000.0,
            "spent_amount": 3820000.0,
            "beneficiaries_target": 200,
            "beneficiaries_registered": 192,
            "progress_pct": 88.0
        },
        {
            "organization": ngo_objs["Pragati Gramin Vikas Trust"],
            "project_id": "PRJ-BLR-2024-01",
            "name": "Rural SC/ST Artisan Livelihood Program",
            "category": "Economic Empowerment",
            "status": "Completed",
            "start_date": date(2024, 7, 1),
            "end_date": date(2025, 6, 30),
            "description": "Direct craft and handloom training with market linkage for 120 rural beneficiaries in Peri-Urban Bengaluru.",
            "sanctioned_amount": 3600000.0,
            "released_amount": 3600000.0,
            "spent_amount": 3580000.0,
            "beneficiaries_target": 120,
            "beneficiaries_registered": 120,
            "progress_pct": 100.0
        },
        {
            "organization": ngo_objs["Chetna Mahila Kalyan Parishad"],
            "project_id": "PRJ-LKO-2025-01",
            "name": "Destitute Women Micro-Enterprise Incubation",
            "category": "Women Livelihoods",
            "status": "Active",
            "start_date": date(2025, 5, 1),
            "end_date": date(2026, 4, 30),
            "description": "Skill development in food processing, packaging, and commercial apparel tailoring for widowed and deserted women.",
            "sanctioned_amount": 3100000.0,
            "released_amount": 2200000.0,
            "spent_amount": 1720000.0,
            "beneficiaries_target": 110,
            "beneficiaries_registered": 98,
            "progress_pct": 60.0
        },
        {
            "organization": ngo_objs["Arogya Drishti Mission"],
            "project_id": "PRJ-JAI-2025-01",
            "name": "Vision Restorative Eyecare for Marginalized Communities",
            "category": "Assistive Healthcare",
            "status": "Active",
            "start_date": date(2025, 3, 1),
            "end_date": date(2026, 2, 28),
            "description": "Free eye screenings, cataract surgeries, and distribution of high-grade corrective lenses to senior citizens living below poverty line.",
            "sanctioned_amount": 4000000.0,
            "released_amount": 3000000.0,
            "spent_amount": 2510000.0,
            "beneficiaries_target": 500,
            "beneficiaries_registered": 485,
            "progress_pct": 74.0
        }
    ]

    project_objs = {}
    for pd in projects_data:
        prj = Project.objects.create(**pd)
        project_objs[prj.project_id] = prj

    print(f"Created {len(project_objs)} Projects.")

    # Seeding Fundings for Projects
    p1 = project_objs["PRJ-DEL-2025-01"]
    Funding.objects.create(
        project=p1,
        source="MoSJE Central Scheme Grant",
        stage="Sanctioned",
        amount=4500000.0,
        date=date(2025, 4, 5),
        purpose="Annual operating and instructor grant under PM-DAKSH",
        reference="SAN-MOSJE-2025-081"
    )
    Funding.objects.create(
        project=p1,
        source="MoSJE First Tranche Release",
        stage="Released",
        amount=3200000.0,
        date=date(2025, 4, 20),
        purpose="Q1-Q3 installment disbursement",
        reference="REL-PFMS-99210"
    )

    # Seeding Expenses
    expenses_data = [
        {"project": p1, "txn_id": "TXN-DEL-8801", "purpose": "Procurement of 25 Braille Displays & Screen Readers", "amount": 625000.0, "vendor": "AssistTech India Pvt Ltd", "date": date(2025, 5, 12), "status": "Verified"},
        {"project": p1, "txn_id": "TXN-DEL-8802", "purpose": "Trainer Honorarium & Pedagogical Materials", "amount": 420000.0, "vendor": "Faculty Welfare Consortium", "date": date(2025, 6, 28), "status": "Verified"},
        {"project": p1, "txn_id": "TXN-DEL-8803", "purpose": "Nutritional Stipend Disbursement for Trainees", "amount": 315000.0, "vendor": "Direct Beneficiary DBT", "date": date(2025, 7, 30), "status": "Verified"},
        {"project": p1, "txn_id": "TXN-DEL-8804", "purpose": "CCTV Infrastructure Upgrades & Broadband", "amount": 180000.0, "vendor": "SecureNet Telecom Delhi", "date": date(2025, 8, 14), "status": "Pending"}
    ]
    for ed in expenses_data:
        Expense.objects.create(**ed)

    # Seeding Beneficiaries
    bens_data = [
        {"project": p1, "name": "Aarav Sharma", "age": 22, "gender": "Male", "service_received": "Assistive Computer Course Certificate", "date": date(2025, 7, 10)},
        {"project": p1, "name": "Pooja Kumari", "age": 24, "gender": "Female", "service_received": "Data Entry & Office Operations Module", "date": date(2025, 7, 15)},
        {"project": p1, "name": "Mohammed Farooq", "age": 21, "gender": "Male", "service_received": "Audio Editing & Screen Reader Tools", "date": date(2025, 8, 2)},
        {"project": p1, "name": "Sunita Verma", "age": 27, "gender": "Female", "service_received": "Financial Literacy & Typing Certification", "date": date(2025, 8, 20)},
        {"project": p1, "name": "Rohan Patel", "age": 19, "gender": "Male", "service_received": "Call Center Operations Skill Badge", "date": date(2025, 9, 5)}
    ]
    for bd in bens_data:
        Beneficiary.objects.create(**bd)

    # Seeding Documents
    doc1_hash = hashlib.sha256(b"SAMPLE_UTILIZATION_CERT_PRJ_DEL_01").hexdigest()
    Document.objects.create(
        project=p1,
        title="Form GFR 12-A Utilization Certificate (H1)",
        doc_type="Utilization Certificate",
        file_url="/media/documents/uc_h1_2025.pdf",
        file_size="1.8 MB",
        sha256_hash=doc1_hash
    )
    doc2_hash = hashlib.sha256(b"SAMPLE_INVOICE_ASSIST_TECH_8801").hexdigest()
    Document.objects.create(
        project=p1,
        title="Tax Invoice - AssistTech Braille Units #8801",
        doc_type="Vendor Invoice",
        file_url="/media/documents/inv_assisttech_8801.pdf",
        file_size="840 KB",
        sha256_hash=doc2_hash
    )

    # Seeding Camera
    Camera.objects.create(
        project=p1,
        name="Classroom 101 - Main Training Lab",
        stream_url="resources/simulated_classroom_cctv.mp4",
        status="Online",
        last_headcount=12,
        expected_headcount=35,
        risk_score=78.5
    )

    # Seeding Alerts
    AlertEvent.objects.create(
        project=p1,
        severity="Critical",
        reason="Automated CCTV Headcount Alert: Detected 12 vs 35 expected capacity (Risk: 78.5%)",
        status="Open"
    )
    AlertEvent.objects.create(
        project=p1,
        severity="Elevated",
        reason="Vendor invoice mismatch flagged on TXN-DEL-8804 (broadband line items)",
        status="Under Review"
    )

    # Seeding Inspections
    # Inspection 1: Dwarka Center (Submitted, Verified, with EXIF, Checklist & SHA-256)
    checklist_1 = {
        "Infrastructure & Classrooms": "Pass",
        "Biometric & Headcount Validation": "Fail",
        "Sanitation & Barrier-Free Access": "Pass",
        "Beneficiary Stipend Records": "Pass",
        "Faculty Attendance & Credentials": "Pass"
    }
    exif_1 = {
        "camera_model": "GovAudit-Handheld-T4",
        "latitude": 28.5921,
        "longitude": 77.0460,
        "altitude_m": 218.4,
        "timestamp": "2026-09-15T11:24:18Z",
        "device_imei_hash": "8f9024a49c66911c42e"
    }
    payload_raw_1 = json.dumps({"inspection_id": "INSP-MOSJE-2026-001", "checklist": checklist_1, "exif": exif_1}, sort_keys=True)
    hash_1 = hashlib.sha256(payload_raw_1.encode('utf-8')).hexdigest()

    Inspection.objects.create(
        inspection_id="INSP-MOSJE-2026-001",
        organization=ngo_objs["Akshaya Vidya Foundation"],
        project=p1,
        assigned_inspector="Inspector Rajesh V.",
        status="Reviewed",
        overall_result="Verified",
        government_review="Verified",
        assigned_date=date(2026, 9, 10),
        submitted_date=date(2026, 9, 15),
        reason="Unannounced AI Discrepancy Dispatch (Classroom Attendance Low)",
        latitude=28.5921,
        longitude=77.0460,
        captured_timestamp=datetime(2026, 9, 15, 11, 24, 18),
        checklist_results=checklist_1,
        photo_watermark_data=exif_1,
        photo_url="/media/evidence/insp_dwarka_001.jpg",
        observations="Center found operating with adequate hardware. Low headcount was temporary due to monsoon morning transport delays. Trainees verified via biometric register.",
        sha256_hash=hash_1
    )

    # Inspection 2: Bandra Mumbai (Submitted, Requires Action)
    checklist_2 = {
        "Ward Cleanliness": "Pass",
        "Medical Records & Pharmacy": "Fail",
        "Safety & Fire Norms": "Pass",
        "Patient Attendance Register": "Fail"
    }
    exif_2 = {
        "camera_model": "GovAudit-Handheld-T4",
        "latitude": 19.0596,
        "longitude": 72.8406,
        "altitude_m": 12.0,
        "timestamp": "2026-09-18T14:10:02Z"
    }
    payload_raw_2 = json.dumps({"inspection_id": "INSP-MOSJE-2026-002", "checklist": checklist_2, "exif": exif_2}, sort_keys=True)
    hash_2 = hashlib.sha256(payload_raw_2.encode('utf-8')).hexdigest()

    Inspection.objects.create(
        inspection_id="INSP-MOSJE-2026-002",
        organization=ngo_objs["Samarpan Seva Samiti"],
        project=project_objs["PRJ-MUM-2025-01"],
        assigned_inspector="Inspector Anita Desai",
        status="Submitted",
        overall_result="Requires Further Action",
        government_review="Requires Further Action",
        assigned_date=date(2026, 9, 14),
        submitted_date=date(2026, 9, 18),
        reason="Routine Annual Mandatory Audit",
        latitude=19.0596,
        longitude=72.8406,
        captured_timestamp=datetime(2026, 9, 18, 14, 10, 2),
        checklist_results=checklist_2,
        photo_watermark_data=exif_2,
        photo_url="/media/evidence/insp_mumbai_002.jpg",
        observations="Medicine stock registers had multiple missing batch entries. Direct explanation requested from Head of Pharmacy.",
        sha256_hash=hash_2
    )

    # Inspection 3: Bengaluru (Assigned - Active task for Inspector Rajesh V.)
    Inspection.objects.create(
        inspection_id="INSP-MOSJE-2026-003",
        organization=ngo_objs["Pragati Gramin Vikas Trust"],
        project=project_objs["PRJ-BLR-2024-01"],
        assigned_inspector="Inspector Rajesh V.",
        status="Assigned",
        overall_result="—",
        government_review="Pending",
        assigned_date=date(2026, 9, 22),
        submitted_date=None,
        reason="Milestone Progress & Final Utilization Verification",
        latitude=12.9784,
        longitude=77.6408,
        captured_timestamp=None,
        checklist_results={},
        photo_watermark_data={},
        observations=""
    )

    # Seeding AuditLogs
    audit_logs_data = [
        {"user": "Admin Sharma", "role": "Admin", "action": "SANCTION_ISSUED", "entity": "Project PRJ-DEL-2025-01 (₹45,00,000)"},
        {"user": "System (AI Stream Processor)", "role": "Admin", "action": "CRITICAL_HEADCOUNT_ALERT", "entity": "Akshaya Vidya Foundation (12/35 present)"},
        {"user": "Director MoSJE", "role": "Admin", "action": "INSPECTION_DISPATCHED", "entity": "INSP-MOSJE-2026-001 to Inspector Rajesh V."},
        {"user": "Inspector Rajesh V.", "role": "Inspector", "action": "GEOLOCK_VERIFIED", "entity": "GeoFence GPS match at 28.5921, 77.0460"},
        {"user": "Inspector Rajesh V.", "role": "Inspector", "action": "INSPECTION_SUBMITTED", "entity": "INSP-MOSJE-2026-001 (SHA-256: " + hash_1[:16] + "...)"},
        {"user": "Admin Sharma", "role": "Admin", "action": "GOVERNMENT_REVIEW_VERIFIED", "entity": "INSP-MOSJE-2026-001 status changed to Verified"},
        {"user": "NGO Rep (Akshaya Vidya)", "role": "NGO Officer", "action": "PROGRESS_REPORT_SUBMITTED", "entity": "Q2 Progress 78% with notes"}
    ]
    for ald in audit_logs_data:
        AuditLog.objects.create(**ald)

    # Seeding IssueReports
    IssueReport.objects.create(
        organization=ngo_objs["Akshaya Vidya Foundation"],
        subject="Delay in Q3 PFMS installment disbursement",
        description="Our second installment request submitted on 15 Aug remains in pending queue. Need urgent clearance for assistive equipment invoice.",
        priority="High",
        status="In Review"
    )

    # Seeding ProgressReport
    ProgressReport.objects.create(
        project=p1,
        progress_pct=78.0,
        beneficiaries_served=142,
        notes="All 5 assistive computer modules completed. 28 candidates already placed in banking back-office apprenticeships."
    )

    print("Successfully seeded full Drishti database with realistic mock data!")

if __name__ == '__main__':
    seed_all()
