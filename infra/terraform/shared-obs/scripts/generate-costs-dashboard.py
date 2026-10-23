#!/usr/bin/env python3
"""Generate dashboards/platform-costs.json from costs/monthly.json (EUR).

AWS month-to-date spend is live via CloudWatch EstimatedCharges (USD) × Frankfurter
USD→EUR — not from monthly.json. Set aws_live false in monthly.json to omit those panels.

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
CLOUDWATCH = {
    "type": "cloudwatch",
    "uid": "${cloudwatch}",
}
EXPR = {"type": "__expr__", "uid": "__expr__"}
MIXED = {"type": "datasource", "uid": "-- Mixed --"}


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
            vendor = v["vendor"]
            if vendor.strip().lower() == "aws":
                # Live CloudWatch panel owns AWS; skip manual rows if someone re-adds them.
                continue
            rows.append(
                {
                    "month": month,
                    "vendor": vendor,
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


def frankfurter_target(ref_id: str = "FX") -> dict:
    # Time column so SSE reduce(last) can treat the frame like a series.
    return {
        "refId": ref_id,
        "type": "json",
        "source": "url",
        "format": "timeseries",
        "parser": "backend",
        "url": "https://api.frankfurter.app/latest?from=USD&to=EUR",
        "url_options": {"method": "GET", "data": ""},
        "root_selector": "",
        "columns": [
            {"selector": "date", "text": "Time", "type": "timestamp"},
            {"selector": "rates.EUR", "text": "eur_per_usd", "type": "number"},
        ],
        "filters": [],
        "data": "",
    }


def cloudwatch_estimated_charges(ref_id: str = "USD") -> dict:
    return {
        "refId": ref_id,
        "queryMode": "Metrics",
        "namespace": "AWS/Billing",
        "metricName": "EstimatedCharges",
        "dimensions": {"Currency": ["USD"]},
        "statistic": "Maximum",
        "period": "21600",
        "region": "us-east-1",
        "matchExact": True,
        "metricQueryType": 0,
        "metricEditorMode": 0,
        "expression": "",
        "sqlExpression": "",
        "label": "AWS USD MTD",
        "id": "",
        "hide": False,
    }


def expr_reduce(ref_id: str, expression: str) -> dict:
    # SSE reducers are last|mean|min|max|sum|count — not panel calcs like lastNotNull.
    return {
        "refId": ref_id,
        "type": "reduce",
        "datasource": EXPR,
        "expression": expression,
        "reducer": "last",
        "settings": {"mode": "dropNN"},
        "hide": True,
    }


def expr_math(ref_id: str, expression: str) -> dict:
    return {
        "refId": ref_id,
        "type": "math",
        "datasource": EXPR,
        "expression": expression,
        "hide": False,
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


def stat_options() -> dict:
    return {
        "reduceOptions": {"calcs": ["lastNotNull"], "fields": "/.*/", "values": False},
        "orientation": "auto",
        "textMode": "auto",
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
    }


def build_dashboard(costs: dict) -> dict:
    aws_live = bool(costs.get("aws_live", True))
    months = costs["months"]
    rows = flatten(months)
    latest = months[-1]["month"]
    latest_rows = [r for r in rows if r["month"] == latest]
    manual_total = sum(r["amount_eur"] for r in latest_rows)
    manual_total_row = [
        {"label": "Non-AWS vendors", "amount_eur": manual_total, "month": latest}
    ]

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

    about = (
        f"**Currency: EUR (€).** Manual feed month: `{latest}`.\n\n"
        "Non-AWS vendors: edit `costs/monthly.json`, run "
        "`scripts/generate-costs-dashboard.py`, `terraform apply`.\n\n"
    )
    if aws_live:
        about += (
            "**AWS is automated:** CloudWatch `AWS/Billing` `EstimatedCharges` "
            "(USD, us-east-1, month-to-date) × [Frankfurter](https://www.frankfurter.app/) "
            "USD→EUR. One-time: enable **Receive CloudWatch Billing Alerts** in AWS "
            "Billing preferences. Updates several times daily — no monthly.json edit."
        )
    else:
        about += "AWS live panels disabled (`aws_live: false`)."

    panels: list[dict] = [
        {
            "id": 1,
            "type": "text",
            "title": "About",
            "gridPos": {"h": 4, "w": 24, "x": 0, "y": 0},
            "options": {"mode": "markdown", "content": about},
        },
        {
            "id": 2,
            "type": "stat",
            "title": f"Non-AWS vendors — {latest}",
            "description": "Sum of operator-maintained rows in costs/monthly.json (AWS excluded).",
            "gridPos": {"h": 6, "w": 6, "x": 0, "y": 4},
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
            "options": stat_options(),
            "targets": [
                inline_target(
                    "MANUAL",
                    manual_total_row,
                    fmt="table",
                    columns=[
                        {"selector": "label", "text": "Label", "type": "string"},
                        {"selector": "amount_eur", "text": "EUR", "type": "number"},
                    ],
                )
            ],
        },
    ]

    y_after_stats = 10
    if aws_live:
        panels.extend(
            [
                {
                    "id": 10,
                    "type": "stat",
                    "title": "AWS MTD (EUR, live)",
                    "description": (
                        "EstimatedCharges (USD) × Frankfurter USD→EUR. "
                        "Requires billing alerts enabled; metric lives in us-east-1."
                    ),
                    "gridPos": {"h": 6, "w": 6, "x": 6, "y": 4},
                    "datasource": MIXED,
                    "fieldConfig": {
                        "defaults": {
                            "unit": "currencyEUR",
                            "decimals": 2,
                            "color": {"mode": "thresholds"},
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {"color": "green", "value": None},
                                    {"color": "yellow", "value": 20},
                                    {"color": "red", "value": 100},
                                ],
                            },
                        },
                        "overrides": [],
                    },
                    "options": stat_options(),
                    "targets": [
                        {
                            **cloudwatch_estimated_charges("USD"),
                            "datasource": CLOUDWATCH,
                            "hide": True,
                        },
                        {
                            **frankfurter_target("FX"),
                            "datasource": INFINITY,
                            "hide": True,
                        },
                        {
                            **expr_reduce("USD_R", "USD"),
                            "hide": True,
                        },
                        {
                            **expr_reduce("FX_R", "FX"),
                            "hide": True,
                        },
                        {
                            **expr_math("EUR", "$USD_R * $FX_R"),
                            "datasource": EXPR,
                        },
                    ],
                },
                {
                    "id": 11,
                    "type": "stat",
                    "title": "AWS MTD (USD, live)",
                    "description": "Raw CloudWatch EstimatedCharges (always USD).",
                    "gridPos": {"h": 6, "w": 6, "x": 12, "y": 4},
                    "datasource": CLOUDWATCH,
                    "fieldConfig": {
                        "defaults": {
                            "unit": "currencyUSD",
                            "decimals": 2,
                            "color": {"mode": "thresholds"},
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {"color": "blue", "value": None},
                                ],
                            },
                        },
                        "overrides": [],
                    },
                    "options": stat_options(),
                    "targets": [
                        {
                            **cloudwatch_estimated_charges("A"),
                            "datasource": CLOUDWATCH,
                        }
                    ],
                },
                {
                    "id": 12,
                    "type": "timeseries",
                    "title": "AWS estimated charges (USD, MTD)",
                    "description": "CloudWatch billing metric history for the selected range.",
                    "gridPos": {"h": 8, "w": 24, "x": 0, "y": 10},
                    "datasource": CLOUDWATCH,
                    "fieldConfig": {
                        "defaults": {
                            "unit": "currencyUSD",
                            "decimals": 2,
                            "custom": {
                                "drawStyle": "line",
                                "lineWidth": 2,
                                "fillOpacity": 20,
                                "spanNulls": True,
                                "showPoints": "auto",
                            },
                        },
                        "overrides": [],
                    },
                    "options": {
                        "legend": {
                            "displayMode": "list",
                            "placement": "bottom",
                            "showLegend": True,
                        },
                        "tooltip": {"mode": "single", "sort": "none"},
                    },
                    "targets": [
                        {
                            **cloudwatch_estimated_charges("A"),
                            "datasource": CLOUDWATCH,
                        }
                    ],
                },
            ]
        )
        y_after_stats = 18

    panels.extend(
        [
            {
                "id": 3,
                "type": "piechart",
                "title": f"Non-AWS by vendor — {latest}",
                "gridPos": {"h": 10, "w": 9, "x": 0, "y": y_after_stats},
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
                    "reduceOptions": {
                        "calcs": ["lastNotNull"],
                        "fields": "",
                        "values": False,
                    },
                    "tooltip": {"mode": "single", "sort": "none"},
                },
                "targets": [
                    inline_target(
                        "A",
                        [
                            {"vendor": r["vendor"], "amount_eur": r["amount_eur"]}
                            for r in latest_rows
                        ],
                        fmt="table",
                        columns=[
                            {"selector": "vendor", "text": "Vendor", "type": "string"},
                            {
                                "selector": "amount_eur",
                                "text": "EUR",
                                "type": "number",
                            },
                        ],
                    )
                ],
            },
            {
                "id": 4,
                "type": "barchart",
                "title": "Non-AWS monthly total (history)",
                "description": "Operator feed only (AWS live is separate).",
                "gridPos": {"h": 10, "w": 15, "x": 9, "y": y_after_stats},
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
                    "legend": {
                        "displayMode": "list",
                        "placement": "bottom",
                        "showLegend": False,
                    },
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
                "targets": [
                    inline_target("A", month_totals, fmt="table", columns=month_cols)
                ],
            },
            {
                "id": 5,
                "type": "table",
                "title": f"Vendor breakdown — {latest}",
                "gridPos": {"h": 10, "w": 14, "x": 0, "y": y_after_stats + 10},
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
                "title": "All months (flat, non-AWS)",
                "gridPos": {"h": 10, "w": 10, "x": 14, "y": y_after_stats + 10},
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
                            {
                                "selector": "amount_eur",
                                "text": "EUR",
                                "type": "number",
                            },
                            {
                                "selector": "project",
                                "text": "Project",
                                "type": "string",
                            },
                            {"selector": "notes", "text": "Notes", "type": "string"},
                        ],
                    )
                ],
            },
        ]
    )

    templating = {
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
    }
    if aws_live:
        templating["list"].append(
            {
                "name": "cloudwatch",
                "type": "datasource",
                "query": "cloudwatch",
                "current": {
                    "text": "CloudWatch Billing",
                    "value": "cloudwatch-billing",
                },
                "hide": 0,
                "includeAll": False,
                "multi": False,
                "refresh": 1,
                "regex": "",
                "skipUrlSync": False,
            }
        )

    return {
        "uid": "platform-costs",
        "title": "Platform — Costs (EUR)",
        "description": (
            "Cross-project operator spend (EUR). Non-AWS from costs/monthly.json; "
            "AWS from CloudWatch EstimatedCharges × Frankfurter when aws_live is true."
        ),
        "tags": ["platform", "costs", "eur", "shared-obs", "aws"],
        "timezone": "browser",
        "schemaVersion": 39,
        "version": 2,
        "refresh": "1h",
        "time": {"from": "now-30d", "to": "now"},
        "templating": templating,
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
