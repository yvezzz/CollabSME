import xml.etree.ElementTree as ET
import os

def create_gantt_svg(filepath):
    tasks = [
        ("Analyse des besoins",                "2026-03-10", "2026-03-31", 100, "#4CAF50"),
        ("Architecture technique",              "2026-03-20", "2026-04-10", 100, "#4CAF50"),
        ("Modèles de données JPA",              "2026-04-01", "2026-04-15", 100, "#4CAF50"),
        ("Auth JWT + Gestion des rôles",        "2026-04-10", "2026-04-30", 100, "#4CAF50"),
        ("CRUD Projets (Backend+Frontend)",     "2026-04-15", "2026-05-10", 100, "#4CAF50"),
        ("Dashboard & Statistiques",            "2026-05-01", "2026-05-20", 100, "#4CAF50"),
        ("Board Kanban & Drag & Drop",          "2026-05-10", "2026-05-30", 100, "#4CAF50"),
        ("Commentaires & Notifications",        "2026-05-15", "2026-06-05", 80,  "#2196F3"),
        ("Membres & Rôles par projet",          "2026-05-20", "2026-06-10", 80,  "#2196F3"),
        ("Intégration IA (OpenRouter)",         "2026-06-01", "2026-06-25", 0,   "#9E9E9E"),
        ("Tests intensifs & Correction bugs",   "2026-06-15", "2026-07-10", 0,   "#9E9E9E"),
        ("Déploiement Docker + Firebase",       "2026-07-01", "2026-07-20", 0,   "#9E9E9E"),
        ("Documentation & Rapport",             "2026-07-10", "2026-07-30", 0,   "#9E9E9E"),
    ]

    from datetime import datetime, timedelta
    ref_start = datetime(2026, 3, 10)
    ref_end = datetime(2026, 7, 30)
    total_days = (ref_end - ref_start).days  # ~142 days

    W, H = 1000, 650
    margin_left, margin_right = 280, 40
    margin_top, margin_bottom = 70, 40
    row_height = 35
    header_height = 30
    gantt_width = W - margin_left - margin_right

    # Build months for x-axis
    months = []
    d = ref_start
    while d <= ref_end:
        mo = d.month
        yr = d.year
        month_end = datetime(yr + 1, 1, 1) if mo == 12 else datetime(yr, mo + 1, 1)
        month_end = min(month_end, ref_end + timedelta(days=1))
        months.append((d, month_end))
        d = month_end

    svg_elements = []

    # Background
    svg_elements.append(f'<rect width="{W}" height="{H}" fill="#1a1a2e" rx="8"/>')
    # Title
    svg_elements.append(f'<text x="{W//2}" y="35" font-family="Arial" font-size="20" font-weight="bold" fill="#ffffff" text-anchor="middle">CollabSME — Diagramme de Gantt (Mars — Juillet 2026)</text>')

    # Month grid
    for i, (m_start, m_end) in enumerate(months):
        x1 = margin_left + (m_start - ref_start).days / total_days * gantt_width
        x2 = margin_left + (m_end - ref_start).days / total_days * gantt_width
        w = x2 - x1
        month_name = ["Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre"][m_start.month - 1]
        svg_elements.append(f'<rect x="{x1}" y="{margin_top - 25}" width="{w}" height="25" fill="#16213e" stroke="#0f3460" stroke-width="1"/>')
        svg_elements.append(f'<text x="{(x1+x2)/2}" y="{margin_top - 7}" font-family="Arial" font-size="12" fill="#a0a0b0" text-anchor="middle">{month_name}</text>')

    # Today marker (May 29, 2026)
    today = datetime(2026, 5, 29)
    today_x = margin_left + (today - ref_start).days / total_days * gantt_width
    svg_elements.append(f'<line x1="{today_x}" y1="{margin_top}" x2="{today_x}" y2="{H - margin_bottom + 10}" stroke="#ff6b6b" stroke-width="2" stroke-dasharray="6,4"/>')
    svg_elements.append(f'<text x="{today_x}" y="{margin_top - 30}" font-family="Arial" font-size="11" fill="#ff6b6b" text-anchor="middle" font-weight="bold">AUJOURD\'HUI</text>')

    # Tasks
    for i, (name, start_str, end_str, progress, color) in enumerate(tasks):
        y = margin_top + header_height + i * row_height + 5
        s = datetime.strptime(start_str, "%Y-%m-%d")
        e = datetime.strptime(end_str, "%Y-%m-%d")
        x1 = margin_left + (s - ref_start).days / total_days * gantt_width
        x2 = margin_left + (e - ref_start).days / total_days * gantt_width
        bw = max(x2 - x1, 4)

        # Task label
        svg_elements.append(f'<text x="{margin_left - 10}" y="{y + row_height//2 + 4}" font-family="Arial" font-size="12" fill="#e0e0e0" text-anchor="end">{name}</text>')

        # Bar background
        svg_elements.append(f'<rect x="{x1}" y="{y}" width="{bw}" height="{row_height - 10}" rx="4" fill="{color}" opacity="0.25" stroke="{color}" stroke-width="1"/>')

        # Progress fill
        if progress > 0:
            pw = bw * progress / 100
            svg_elements.append(f'<rect x="{x1}" y="{y}" width="{pw}" height="{row_height - 10}" rx="4" fill="{color}" opacity="0.8"/>')

        # Progress text on bar
        if bw > 40:
            svg_elements.append(f'<text x="{x1 + bw/2}" y="{y + (row_height - 10)//2 + 4}" font-family="Arial" font-size="10" fill="#ffffff" text-anchor="middle" font-weight="bold">{progress}%</text>')
        else:
            svg_elements.append(f'<text x="{x2 + 4}" y="{y + (row_height - 10)//2 + 4}" font-family="Arial" font-size="10" fill="{color}">{progress}%</text>')

        # Horizontal grid line
        svg_elements.append(f'<line x1="{margin_left}" y1="{y + row_height}" x2="{W - margin_right}" y2="{y + row_height}" stroke="#0f3460" stroke-width="0.5"/>')

    # Legend
    lx, ly = margin_left, H - 28
    svg_elements.append(f'<rect x="{lx}" y="{ly}" width="12" height="12" fill="#4CAF50" rx="2"/>')
    svg_elements.append(f'<text x="{lx + 16}" y="{ly + 10}" font-family="Arial" font-size="11" fill="#a0a0b0">Terminé (100%)</text>')
    svg_elements.append(f'<rect x="{lx + 110}" y="{ly}" width="12" height="12" fill="#2196F3" rx="2"/>')
    svg_elements.append(f'<text x="{lx + 126}" y="{ly + 10}" font-family="Arial" font-size="11" fill="#a0a0b0">En cours</text>')
    svg_elements.append(f'<rect x="{lx + 210}" y="{ly}" width="12" height="12" fill="#9E9E9E" rx="2"/>')
    svg_elements.append(f'<text x="{lx + 226}" y="{ly + 10}" font-family="Arial" font-size="11" fill="#a0a0b0">À venir</text>')
    svg_elements.append(f'<line x1="{lx + 320}" y1="{ly + 6}" x2="{lx + 340}" y2="{ly + 6}" stroke="#ff6b6b" stroke-width="2" stroke-dasharray="4,3"/>')
    svg_elements.append(f'<text x="{lx + 346}" y="{ly + 10}" font-family="Arial" font-size="11" fill="#a0a0b0">Aujourd\'hui (29 mai)</text>')

    svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
    {"".join(svg_elements)}
</svg>'''
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"✓ Gantt SVG créé : {filepath}")

def create_architecture_svg(filepath):
    W, H = 1200, 850
    svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
    <defs>
        <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stop-color="#0f0c29"/>
            <stop offset="50%" stop-color="#302b63"/>
            <stop offset="100%" stop-color="#24243e"/>
        </linearGradient>
        <filter id="shadow" x="-5%" y="-5%" width="110%" height="110%">
            <feDropShadow dx="2" dy="3" stdDeviation="4" flood-color="#000" flood-opacity="0.4"/>
        </filter>
    </defs>
    <rect width="{W}" height="{H}" fill="url(#bg)" rx="12"/>

    <!-- Title -->
    <text x="{W//2}" y="45" font-family="Arial" font-size="22" font-weight="bold" fill="#ffffff" text-anchor="middle" filter="url(#shadow)">CollabSME — Architecture Globale</text>

    <!-- Client Box -->
    <rect x="50" y="70" width="240" height="200" rx="10" fill="#1a1a2e" stroke="#4CAF50" stroke-width="2" filter="url(#shadow)"/>
    <rect x="50" y="70" width="240" height="35" rx="10" fill="#4CAF50"/>
    <rect x="50" y="90" width="240" height="15" fill="#4CAF50"/>
    <text x="170" y="93" font-family="Arial" font-size="14" font-weight="bold" fill="#fff" text-anchor="middle">🧑‍💻 Client</text>
    <text x="170" y="125" font-family="Arial" font-size="12" fill="#e0e0e0" text-anchor="middle">Flutter Web 3.29+</text>
    <text x="170" y="147" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Firebase Hosting</text>
    <text x="170" y="167" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">State: Riverpod</text>
    <text x="170" y="187" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">UI: Glassmorphism sombre</text>
    <text x="170" y="207" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Charts: fl_chart</text>
    <text x="170" y="227" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Calendrier: table_calendar</text>
    <text x="170" y="255" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Renderer: CanvasKit</text>

    <!-- API REST Box -->
    <rect x="350" y="70" width="240" height="160" rx="10" fill="#1a1a2e" stroke="#FF9800" stroke-width="2" filter="url(#shadow)"/>
    <rect x="350" y="70" width="240" height="35" rx="10" fill="#FF9800"/>
    <rect x="350" y="90" width="240" height="15" fill="#FF9800"/>
    <text x="470" y="93" font-family="Arial" font-size="14" font-weight="bold" fill="#fff" text-anchor="middle">🔌 API REST (JSON)</text>
    <text x="470" y="125" font-family="Arial" font-size="12" fill="#e0e0e0" text-anchor="middle">JWT Bearer Token</text>
    <text x="470" y="147" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">jjwt 0.12.6</text>
    <text x="470" y="167" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Jackson Snake Case</text>
    <text x="470" y="187" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Endpoints versionnés</text>
    <text x="470" y="207" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Stateless Security</text>

    <!-- Backend Box -->
    <rect x="650" y="70" width="500" height="360" rx="10" fill="#1a1a2e" stroke="#2196F3" stroke-width="2" filter="url(#shadow)"/>
    <rect x="650" y="70" width="500" height="35" rx="10" fill="#2196F3"/>
    <rect x="650" y="90" width="500" height="15" fill="#2196F3"/>
    <text x="900" y="93" font-family="Arial" font-size="14" font-weight="bold" fill="#fff" text-anchor="middle">⚙️ Backend Spring Boot 3.4.4 (Java 21)</text>

    <!-- Controllers sub-box -->
    <rect x="670" y="120" width="220" height="150" rx="8" fill="#16213e" stroke="#64B5F6" stroke-width="1"/>
    <text x="780" y="140" font-family="Arial" font-size="12" font-weight="bold" fill="#64B5F6" text-anchor="middle">Controllers</text>
    <text x="780" y="158" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">AuthController</text>
    <text x="780" y="175" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">ProjectController</text>
    <text x="780" y="192" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">TaskController</text>
    <text x="780" y="209" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">ActivityLogController</text>
    <text x="780" y="226" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">NotificationController</text>
    <text x="780" y="243" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">InvitationController</text>
    <text x="780" y="260" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">AIController</text>

    <!-- Services sub-box -->
    <rect x="910" y="120" width="220" height="150" rx="8" fill="#16213e" stroke="#64B5F6" stroke-width="1"/>
    <text x="1020" y="140" font-family="Arial" font-size="12" font-weight="bold" fill="#64B5F6" text-anchor="middle">Services</text>
    <text x="1020" y="158" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">AuthService</text>
    <text x="1020" y="175" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">ProjectService</text>
    <text x="1020" y="192" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">TaskService</text>
    <text x="1020" y="209" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">NotificationService</text>
    <text x="1020" y="226" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">CompanyService</text>
    <text x="1020" y="243" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">AIService</text>

    <!-- Models JPA sub-box -->
    <rect x="670" y="285" width="460" height="130" rx="8" fill="#16213e" stroke="#4DD0E1" stroke-width="1"/>
    <text x="900" y="305" font-family="Arial" font-size="12" font-weight="bold" fill="#4DD0E1" text-anchor="middle">Modèles JPA (15 tables)</text>
    <text x="720" y="325" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">User / Company</text>
    <text x="900" y="325" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">Project / Task / Comment</text>
    <text x="1080" y="325" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">ChecklistItem / Attachment</text>
    <text x="720" y="345" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">ActivityLog / Notification</text>
    <text x="900" y="345" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">Invitation / AIChat</text>
    <text x="1080" y="345" font-family="Arial" font-size="11" fill="#e0e0e0" text-anchor="middle">PasswordResetToken</text>

    <!-- DB Box -->
    <rect x="50" y="310" width="240" height="180" rx="10" fill="#1a1a2e" stroke="#9C27B0" stroke-width="2" filter="url(#shadow)"/>
    <rect x="50" y="310" width="240" height="35" rx="10" fill="#9C27B0"/>
    <rect x="50" y="330" width="240" height="15" fill="#9C27B0"/>
    <text x="170" y="333" font-family="Arial" font-size="14" font-weight="bold" fill="#fff" text-anchor="middle">🗄️ Base de Données</text>
    <text x="170" y="365" font-family="Arial" font-size="12" fill="#e0e0e0" text-anchor="middle">MySQL via XAMPP</text>
    <text x="170" y="387" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">15 tables</text>
    <text x="170" y="407" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">ORM : JPA / Hibernate</text>
    <text x="170" y="427" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Database : collabsme</text>
    <text x="170" y="447" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">DDL auto : update</text>
    <text x="170" y="467" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Seed data : 4 users / 7 projets / 20 tâches</text>

    <!-- External Services Box -->
    <rect x="50" y="530" width="240" height="160" rx="10" fill="#1a1a2e" stroke="#F44336" stroke-width="2" filter="url(#shadow)"/>
    <rect x="50" y="530" width="240" height="35" rx="10" fill="#F44336"/>
    <rect x="50" y="550" width="240" height="15" fill="#F44336"/>
    <text x="170" y="553" font-family="Arial" font-size="14" font-weight="bold" fill="#fff" text-anchor="middle">📡 Services Externes</text>
    <text x="170" y="585" font-family="Arial" font-size="12" fill="#e0e0e0" text-anchor="middle">Brevo REST API (Emails)</text>
    <text x="170" y="607" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">OpenRouter / OpenAI (IA)</text>
    <text x="170" y="627" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Firebase Hosting</text>
    <text x="170" y="647" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">ngrok (tunnel dev)</text>
    <text x="170" y="667" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">WebSocket temps réel</text>

    <!-- Security Box -->
    <rect x="350" y="530" width="240" height="160" rx="10" fill="#1a1a2e" stroke="#FF5722" stroke-width="2" filter="url(#shadow)"/>
    <rect x="350" y="530" width="240" height="35" rx="10" fill="#FF5722"/>
    <rect x="350" y="550" width="240" height="15" fill="#FF5722"/>
    <text x="470" y="553" font-family="Arial" font-size="14" font-weight="bold" fill="#fff" text-anchor="middle">🔐 Sécurité</text>
    <text x="470" y="585" font-family="Arial" font-size="12" fill="#e0e0e0" text-anchor="middle">JWT stateless</text>
    <text x="470" y="607" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">BCrypt (mots de passe)</text>
    <text x="470" y="627" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Spring Security Filter Chain</text>
    <text x="470" y="647" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">Rôles : ADMIN / LEAD / MEMBER</text>
    <text x="470" y="667" font-family="Arial" font-size="11" fill="#a0a0b0" text-anchor="middle">CORS configuré</text>

    <!-- Arrows between layers -->
    <!-- Client -> API -->
    <line x1="290" y1="170" x2="345" y2="170" stroke="#FF9800" stroke-width="2" stroke-dasharray="6,3" marker-end="url(#arrow-orange)"/>
    <!-- API -> Backend -->
    <line x1="590" y1="170" x2="645" y2="170" stroke="#2196F3" stroke-width="2" stroke-dasharray="6,3"/>
    <!-- Backend -> DB -->
    <line x1="650" y1="390" x2="295" y2="390" stroke="#9C27B0" stroke-width="2"/>
    <line x1="295" y1="390" x2="295" y2="400" stroke="#9C27B0" stroke-width="2"/>
    <line x1="295" y1="400" x2="650" y2="400" stroke="#9C27B0" stroke-width="2"/>
    <!-- Backend -> External -->
    <line x1="650" y1="440" x2="295" y2="600" stroke="#F44336" stroke-width="1.5" stroke-dasharray="5,3"/>

    <!-- Arrow marker definitions -->
    <defs>
        <marker id="arrow-orange" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto">
            <path d="M 0 0 L 10 5 L 0 10 z" fill="#FF9800"/>
        </marker>
        <marker id="arrow-blue" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto">
            <path d="M 0 0 L 10 5 L 0 10 z" fill="#2196F3"/>
        </marker>
        <marker id="arrow-purple" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto">
            <path d="M 0 0 L 10 5 L 0 10 z" fill="#9C27B0"/>
        </marker>
    </defs>
</svg>'''
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"✓ Architecture SVG créé : {filepath}")

if __name__ == "__main__":
    output_dir = r"C:\Users\user\StudioProjects\koda"
    create_gantt_svg(os.path.join(output_dir, "gantt_diagram.svg"))
    create_architecture_svg(os.path.join(output_dir, "architecture_diagram.svg"))
    print("\\n✅ Les deux fichiers SVG sont prêts !")
    print("📌 Importez-les dans Edraw Max via : Importer → Importer le fichier SVG")
