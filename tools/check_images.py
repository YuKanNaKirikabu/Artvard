from __future__ import annotations

import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
import time


try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass


def _read_api_key(project_root: Path) -> str:
    api_path = project_root / "lib" / "services" / "harvard_api.dart"
    text = api_path.read_text(encoding="utf-8")
    match = re.search(r"apiKey\s*=\s*'([^']+)'", text)
    if not match:
        raise RuntimeError("API key not found in harvard_api.dart")
    return match.group(1)


def _normalize_url(url: str | None) -> str | None:
    if not url:
        return None
    value = url.strip()
    if not value:
        return None
    if value.startswith("http://"):
        return "https://" + value[len("http://") :]
    return value


def _looks_like_iiif_base(url: str) -> bool:
    lower = url.lower()
    return (
        "/iiif/" in lower
        and "/full/" not in lower
        and not lower.endswith((".jpg", ".jpeg", ".png", ".webp"))
    )


def _build_iiif_url(base: str, size: int) -> str:
    return f"{base}/full/!{size},{size}/0/default.jpg"


def _extract_candidates(record: dict, size: int) -> list[str]:
    candidates: list[str] = []

    def add(value: str | None) -> None:
        normalized = _normalize_url(value)
        if normalized and normalized not in candidates:
            candidates.append(normalized)

    add(record.get("primaryimageurl"))
    add(record.get("baseimageurl"))

    images = record.get("images") or []
    if isinstance(images, list):
        for image in images:
            if isinstance(image, dict):
                add(image.get("primaryimageurl"))
                add(image.get("imageurl"))
                add(image.get("baseimageurl"))
                add(image.get("iiifbaseuri"))

    expanded: list[str] = []
    for url in candidates:
        if _looks_like_iiif_base(url):
            iiif_url = _build_iiif_url(url, size)
            if iiif_url not in expanded:
                expanded.append(iiif_url)
        if url not in expanded:
            expanded.append(url)

    return expanded


def _check_url(url: str) -> tuple[str, str | None]:
    request = urllib.request.Request(
        url,
        method="GET",
        headers={"Range": "bytes=0-0", "User-Agent": "Mozilla/5.0"},
    )
    try:
        with urllib.request.urlopen(request, timeout=3) as response:
            status = str(response.status)
            content_type = response.headers.get("Content-Type")
            return status, content_type
    except urllib.error.HTTPError as error:
        return str(error.code), error.headers.get("Content-Type")
    except Exception as error:  # noqa: BLE001
        return type(error).__name__, None


def main() -> int:
    project_root = Path(__file__).resolve().parents[1]
    api_key = _read_api_key(project_root)

    size = 100
    pages = 3
    max_per_record = 2
    has_image = True
    verbose_ok = False
    progress_every = 25
    summary_path = project_root / "tools" / "image_check_summary.txt"

    print(
        "Running diagnostics: "
        f"pages={pages} size={size} has_image={has_image}"
    )

    ok_count = 0
    fail_count = 0
    no_image_count = 0
    error_count = 0
    checked_count = 0
    fail_log = project_root / "tools" / "image_failures.log"
    fail_log.write_text("", encoding="utf-8")

    started_at = time.time()

    with fail_log.open("a", encoding="utf-8") as fail_handle:
        for page in range(1, pages + 1):
            params = {
                "apikey": api_key,
                "size": size,
                "page": page,
            }
            if has_image:
                params["hasimage"] = 1

            url = "https://api.harvardartmuseums.org/object?" + urllib.parse.urlencode(
                params
            )

            with urllib.request.urlopen(url, timeout=20) as response:
                payload = json.load(response)

            records = payload.get("records") or []
            if not records:
                print(f"No records returned from API on page {page}")
                break

            for record in records:
                if not isinstance(record, dict):
                    print("SKIP: non-dict record")
                    error_count += 1
                    continue

                checked_count += 1
                record_id = record.get("id")
                title = (record.get("title") or "").strip()
                candidates = _extract_candidates(record, size=600)
                if not candidates:
                    no_image_count += 1
                    continue

                statuses = []
                success = None
                for candidate in candidates[:max_per_record]:
                    status, content_type = _check_url(candidate)
                    statuses.append(status)
                    if status in {"200", "206", "302", "304"}:
                        success = (status, content_type or "")
                        break

                if success is None:
                    fail_count += 1
                    fail_handle.write(
                        f"ID {record_id}: {title}\n"
                        f"  statuses={','.join(statuses)}\n"
                        "  candidates:\n"
                        + "".join(
                            f"    {url}\n" for url in candidates[:max_per_record]
                        )
                        + "\n"
                    )
                    print(
                        f"ID {record_id}: FAIL {','.join(statuses)} | {title[:40]}"
                    )
                else:
                    status, content_type = success
                    if verbose_ok or checked_count % progress_every == 0:
                        print(
                            "PROGRESS: "
                            f"checked={checked_count} ok={ok_count + 1} "
                            f"fail={fail_count} no_image={no_image_count}"
                        )
                    ok_count += 1

    elapsed = time.time() - started_at
    print(
        "Summary: "
        f"checked={checked_count} ok={ok_count} fail={fail_count} "
        f"no_image={no_image_count} errors={error_count} "
        f"pages={pages} size={size} elapsed={elapsed:.1f}s"
    )
    print(f"Failure log: {fail_log}")

    summary_path.write_text(
        "Summary: "
        f"checked={checked_count} ok={ok_count} fail={fail_count} "
        f"no_image={no_image_count} errors={error_count} "
        f"pages={pages} size={size} elapsed={elapsed:.1f}s\n"
        f"Failure log: {fail_log}\n",
        encoding="utf-8",
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
