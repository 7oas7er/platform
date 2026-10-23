#!/usr/bin/env python3
"""Generate dashboards/platform-costs.json from costs/monthly.json (EUR).

Usage (from shared-obs root):
  python3 scripts/generate-costs-dashboard.py
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COSTS_PATH = ROOT / "costs" / "monthly.json"
OUT_PATH = ROOT / "dashboards" / "platform-costs.json"

INFINITY = {
    "type": "yesoreyeram-infinity-datasource",
    "uid": "${infinity}",
}


def load_costs() -> dict:
    data = json.loads(COSTS_PATH.read_text(encoding="utf-8"))
    if data.get("currency") != "EUR":
        raise SystemExit(f"currency must be EUR, got {data.get('currency')!r}")
    if not data.get("months"):
        raise SystemExit("costs/monthly.json needs at least one month")
    return data


def flatten(months: list[dict]) -> list[dict]:
    rows: list[dict] = []
    for m in months:
        month = m["month"]
        for v in m["by_vendor"]:
            rows.append(
                {
                    "month": month,
                    "vendor": v["vendor"],
                    "amount_eur": float(v["amount_eur"]),
                    "project": v.get("project") or "shared",
                    "notes": v.get("notes") or "",
                }
            )
    return rows


def inline_target(
    ref_id: str,
    rows: list[dict],
    *,
    fmt: str,
    columns: list[dict],
) -> dict:
    return {
        "refId": ref_id,
        "type": "json",
        "source": "inline",
        "format": fmt,
        "parser": "backend",
        "data": json.dumps(rows, separators=(",", ":")),
        "root_selector": "",
        "columns": columns,
        "filters": [],
        "url": "",
        "url_options": {"method": "GET", "data": ""},
    }


def eur_field(overrides: list | None = None) -> dict:
    return {
        "defaults": {
            "unit": "currencyEUR",
            "decimals": 2,
            "custom": {"align": "auto", "cellOptions": {"type": "auto"}, "inspect": False},
        },
        "overrides": overrides or [],
    }


def build_dashboard(costs: dict) -> dict:
    months = costs["months"]
    rows = flatten(months)
    latest = months[-1]["month"]
    latest_rows = [r for r in rows if r["month"] == latest]
    total_latest = sum(r["amount_eur"] for r in latest_rows)
    total_row = [{"label": "Total", "amount_eur": total_latest, "month": latest}]

    # One row per month for history bar chart.
    by_month: dict[str, float] = {}
    for r in rows:
        by_month[r["month"]] = by_month.get(r["month"], 0.0) + r["amount_eur"]
    month_totals = [{"month": m, "amount_eur": by_month[m]} for m in sorted(by_month)]

    vendor_cols = [
        {"selector": "vendor", "text": "Vendor", "type": "string"},
        {"selector": "amount_eur", "text": "EUR", "type": "number"},
        {"selector": "project", "text": "Project", "type": "string"},
        {"selector": "notes", "text": "Notes", "type": "string"},
    ]
    month_cols = [
        {"selector": "month", "text": "Month", "type": "string"},
        {"selector": "amount_eur", "text": "EUR", "type": "number"},
    ]

    panels = [
        {
            "id": 1,
            "type": "text",
            "title": "About",
            "gridPos": {"h": 3, "w": 24, "x": 0, "y": 0},
            "options": {
                "mode": "markdown",
                "content": (
                    f"**Currency: EUR (€).** Latest month in feed: `{latest}`.\n\n"
                    "P0: edit `costs/monthly.json`, run `scripts/generate-costs-dashboard.py`, "
                    "`terraform apply` in `shared-obs`. "
                    "Later: AWS Cost Explorer / vendor APIs where available; subscriptions may stay manual."
                ),
            },
        },
        {
            "id": 2,
            "type": "stat",
            "title": f"Total — {latest}",
            "description": "Sum of vendor amounts for the latest month in costs/monthly.json.",
            "gridPos": {"h": 6, "w": 6, "x": 0, "y": 3},
            "datasource": INFINITY,
            "fieldConfig": {
                "defaults": {
                    "unit": "currencyEUR",
                    "decimals": 2,
                    "color": {"mode": "thresholds"},
                    "thresholds": {
                        "mode": "absolute",
                        "steps": [
                            {"color": "green", "value": None},
                            {"color": "yellow", "value": 50},
                            {"color": "red", "value": 200},
                        ],
                    },
                },
                "overrides": [],
            },
            "options": {
                "reduceOptions": {"calcs": ["lastNotNull"], "fields": "/.*/", "values": False},
                "orientation": "auto",
                "textMode": "auto",
                "colorMode": "value",
                "graphMode": "none",
                "justifyMode": "auto",
            },
            "targets": [
                inline_target(
                    "A",
                    total_row,
                    fmt="table",
                    columns=[
                        {"selector": "label", "text": "Label", "type": "string"},
                        {"selector": "amount_eur", "text": "EUR", "type": "number"},
                    ],
                )
            ],
        },
        {
            "id": 3,
            "type": "piechart",
            "title": f"By vendor — {latest}",
            "gridPos": {"h": 10, "w": 9, "x": 6, "y": 3},
            "datasource": INFINITY,
            "fieldConfig": eur_field(),
            "options": {
                "pieType": "donut",
                "displayLabels": ["name", "percent"],
                "legend": {
                    "displayMode": "table",
                    "placement": "right",
                    "showLegend": True,
                    "values": ["value", "percent"],
                },
                "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False},
                "tooltip": {"mode": "single", "sort": "none"},
            },
            "targets": [
                inline_target(
                    "A",
                    [{"vendor": r["vendor"], "amount_eur": r["amount_eur"]} for r in latest_rows],
                    fmt="table",
                    columns=[
                        {"selector": "vendor", "text": "Vendor", "type": "string"},
                        {"selector": "amount_eur", "text": "EUR", "type": "number"},
                    ],
                )
            ],
        },
        {
            "id": 4,
            "type": "barchart",
            "title": "Monthly total (history)",
            "description": "One bar per month in the feed (EUR).",
            "gridPos": {"h": 10, "w": 9, "x": 15, "y": 3},
            "datasource": INFINITY,
            "fieldConfig": {
                "defaults": {
                    "unit": "currencyEUR",
                    "decimals": 2,
                    "custom": {
                        "lineWidth": 1,
                        "fillOpacity": 80,
                        "gradientMode": "none",
                        "axisPlacement": "auto",
                    },
                },
                "overrides": [],
            },
            "options": {
                "legend": {"displayMode": "list", "placement": "bottom", "showLegend": False},
                "tooltip": {"mode": "single", "sort": "none"},
                "barWidth": 0.7,
                "groupWidth": 0.7,
                "xTickLabelRotation": 0,
                "xTickLabelSpacing": 0,
                "showValue": "always",
                "stacking": "none",
                "orientation": "vertical",
                "xField": "Month",
            },
            "targets": [inline_target("A", month_totals, fmt="table", columns=month_cols)],
        },
        {
            "id": 5,
            "type": "table",
            "title": f"Vendor breakdown — {latest}",
            "gridPos": {"h": 10, "w": 14, "x": 0, "y": 13},
            "datasource": INFINITY,
            "fieldConfig": eur_field(
                [
                    {
                        "matcher": {"id": "byName", "options": "EUR"},
                        "properties": [
                            {"id": "unit", "value": "currencyEUR"},
                            {"id": "decimals", "value": 2},
                        ],
                    }
                ]
            ),
            "options": {
                "showHeader": True,
                "cellHeight": "sm",
                "footer": {"show": False, "reducer": ["sum"], "fields": ""},
            },
            "targets": [
                inline_target(
                    "A",
                    [
                        {
                            "vendor": r["vendor"],
                            "amount_eur": r["amount_eur"],
                            "project": r["project"],
                            "notes": r["notes"],
                        }
                        for r in latest_rows
                    ],
                    fmt="table",
                    columns=vendor_cols,
                )
            ],
        },
        {
            "id": 6,
            "type": "table",
            "title": "All months (flat)",
            "description": "Full history from costs/monthly.json for spot checks.",
            "gridPos": {"h": 10, "w": 10, "x": 14, "y": 13},
            "datasource": INFINITY,
            "fieldConfig": eur_field(
                [
                    {
                        "matcher": {"id": "byName", "options": "EUR"},
                        "properties": [
                            {"id": "unit", "value": "currencyEUR"},
                            {"id": "decimals", "value": 2},
                        ],
                    }
                ]
            ),
            "options": {
                "showHeader": True,
                "cellHeight": "sm",
                "footer": {"show": False, "reducer": ["sum"], "fields": ""},
            },
            "targets": [
                inline_target(
                    "A",
                    rows,
                    fmt="table",
                    columns=[
                        {"selector": "month", "text": "Month", "type": "string"},
                        {"selector": "vendor", "text": "Vendor", "type": "string"},
                        {"selector": "amount_eur", "text": "EUR", "type": "number"},
                        {"selector": "project", "text": "Project", "type": "string"},
                        {"selector": "notes", "text": "Notes", "type": "string"},
                    ],
                )
            ],
        },
    ]

    return {
        "uid": "platform-costs",
        "title": "Platform — Costs (EUR)",
        "description": (
            "Cross-project operator spend overview (EUR). Owned by 7oas7er/platform shared-obs. "
            "P0 feed: costs/monthly.json."
        ),
        "tags": ["platform", "costs", "eur", "shared-obs"],
        "timezone": "browser",
        "schemaVersion": 39,
        "version": 1,
        "refresh": "",
        "time": {"from": "now-30d", "to": "now"},
        "templating": {
            "list": [
                {
                    "name": "infinity",
                    "type": "datasource",
                    "query": "yesoreyeram-infinity-datasource",
                    "current": {
                        "text": "Platform costs",
                        "value": "infinity-platform",
                    },
                    "hide": 0,
                    "includeAll": False,
                    "multi": False,
                    "refresh": 1,
                    "regex": "",
                    "skipUrlSync": False,
                }
            ]
        },
        "annotations": {"list": []},
        "panels": panels,
    }


def main() -> None:
    costs = load_costs()
    dash = build_dashboard(costs)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(dash, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
