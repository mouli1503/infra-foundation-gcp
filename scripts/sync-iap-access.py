#!/usr/bin/env python3
"""Pull live IAP members from GCP into iap_route_access in terraform.tfvars.

The iap_access binding is authoritative, so anything granted via gcloud gets
revoked on the next apply. This unions live members into config so the drift
stops. Union, never replace: routes whose backend does not exist yet (new
routes) keep their configured members.

  ./scripts/sync-iap-access.py                  # dry run, prints diff
  ./scripts/sync-iap-access.py --write          # rewrite tfvars
  ./scripts/sync-iap-access.py --self-test      # parser check, no GCP calls
"""
import json, re, subprocess, sys, pathlib

TFVARS = pathlib.Path(__file__).resolve().parent.parent / "environments/supertails-internal/terraform.tfvars"
ROLE = "roles/iap.httpsResourceAccessor"
ENTRY = re.compile(r'^\s*"?([\w.\-]+)"?\s*[:=]\s*\[([^\]]*)\]\s*$')


def find_block(text, name):
    """Return (start, end) char offsets of the `name = { ... }` body, braces included."""
    m = re.search(rf'^{re.escape(name)}\s*=\s*\{{', text, re.M)
    if not m:
        raise SystemExit(f"{name} block not found in {TFVARS}")
    close = text.index("\n}", m.end())
    return m.start(), close + 2


def parse_map(block):
    """Flat HCL map of key -> list of strings. Tolerates both `=` and `:` separators."""
    out = {}
    for line in block.splitlines()[1:-1]:
        m = ENTRY.match(line)
        if m:
            out[m.group(1)] = [v.strip().strip('"') for v in m.group(2).split(",") if v.strip()]
    return out


def render_map(name, data):
    lines = [f"{name} = {{"]
    for k, members in data.items():
        vals = ", ".join(f'"{v}"' for v in members)
        lines.append(f'  "{k}" = [{vals}]')
    lines.append("}")
    return "\n".join(lines)


def live_members(project, backend):
    cmd = ["gcloud", "iap", "web", "get-iam-policy",
           "--resource-type=backend-services", f"--service={backend}",
           f"--project={project}", "--format=json"]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        print(f"  ! skip {backend}: {p.stderr.strip().splitlines()[-1] if p.stderr.strip() else 'query failed'}", file=sys.stderr)
        return None
    policy = json.loads(p.stdout or "{}")
    for b in policy.get("bindings", []):
        if b.get("role") == ROLE:
            return b.get("members", [])
    return []


def self_test():
    src = 'iap_route_access = {\n  "a" = ["group:x@y.com"]\n  "b": ["domain:y.com", "user:z@y.com"]\n}\n'
    s, e = find_block(src, "iap_route_access")
    parsed = parse_map(src[s:e])
    assert parsed == {"a": ["group:x@y.com"], "b": ["domain:y.com", "user:z@y.com"]}, parsed
    # `:` separator normalises to `=` on render, and round-trips
    out = render_map("iap_route_access", parsed)
    s2, e2 = find_block(out + "\n", "iap_route_access")
    assert parse_map(out[s2:e2]) == parsed
    # real file parses, and every protected route has an entry or falls back to defaults
    text = TFVARS.read_text()
    s3, e3 = find_block(text, "iap_route_access")
    assert len(parse_map(text[s3:e3])) > 0
    print("self-test ok")


def main():
    if "--self-test" in sys.argv:
        return self_test()

    text = TFVARS.read_text()
    project = re.search(r'^project_id\s*=\s*"([^"]+)"', text, re.M).group(1)
    protected = re.search(r'^iap_protected_routes\s*=\s*\[([^\]]*)\]', text, re.M).group(1)
    protected = [v.strip().strip('"') for v in protected.split(",") if v.strip()]

    start, end = find_block(text, "iap_route_access")
    config = parse_map(text[start:end])

    merged, added, skipped = {}, [], []
    for route in protected:
        have = config.get(route, [])
        backend = "bs-" + route.replace(".", "-")
        live = live_members(project, backend)
        if live is None:                      # backend missing or query failed: never drop config
            merged[route] = have
            skipped.append(route)
            continue
        new = [m for m in live if m not in have]
        added += [(route, m) for m in new]
        merged[route] = have + sorted(new)

    for route, members in config.items():     # keep entries for unprotected routes untouched
        merged.setdefault(route, members)

    if skipped:
        print(f"WARNING: could not read live policy for {len(skipped)}/{len(protected)} routes "
              f"({', '.join(skipped)}). Drift there is unknown, not absent.")
        if len(skipped) == len(protected):
            raise SystemExit("no route could be queried; check `gcloud auth login` and project access")

    if not added:
        print("no drift: config already covers every live IAP member")
        return

    print("members granted out-of-band, being pulled into config:")
    for route, m in added:
        print(f"  + {route}: {m}")

    if "--write" not in sys.argv:
        print("\ndry run. re-run with --write to apply, then `make plan-internal` to confirm clean.")
        return

    TFVARS.write_text(text[:start] + render_map("iap_route_access", merged) + text[end:])
    print(f"\nwrote {TFVARS}")


main()
