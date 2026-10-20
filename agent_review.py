"""Publish a completed agent review as a commit-specific GitHub status.

This command records a review supplied by the operator; it does not perform
the review or submit a GitHub approval. Authentication comes from the gh CLI.
"""

from __future__ import annotations

import argparse
from collections.abc import Callable
import json
from pathlib import Path
import re
import subprocess
import sys
from typing import Any
from urllib.parse import quote, urlparse


CONTEXT = "agent-review"
Api = Callable[[str, str, dict[str, Any] | None], dict[str, Any]]
SHA_PATTERN = re.compile(r"[0-9a-f]{40}")
REPO_PATTERN = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")


class ReviewError(Exception):
    """The review could not be recorded safely."""


def gh_api(method: str, path: str, payload: dict[str, Any] | None) -> dict[str, Any]:
    command = ["gh", "api", "--method", method, path]
    if payload is not None:
        command.extend(["--input", "-"])
    try:
        result = subprocess.run(
            command,
            input=json.dumps(payload) if payload is not None else None,
            capture_output=True,
            text=True,
            check=True,
        )
        response = json.loads(result.stdout)
    except FileNotFoundError as error:
        raise ReviewError("The authenticated gh CLI must be installed.") from error
    except subprocess.CalledProcessError as error:
        raise ReviewError(f"GitHub API failed: {error.stderr.strip()}") from error
    except json.JSONDecodeError as error:
        raise ReviewError("GitHub returned an invalid JSON response.") from error
    if not isinstance(response, dict):
        raise ReviewError("GitHub returned an unexpected response type.")
    return response


def validate_commit(api: Api, repo: str, number: int, head: str, base: str) -> str:
    pull = api("GET", f"repos/{repo}/pulls/{number}", None)
    try:
        current_head = pull["head"]["sha"]
        current_base = pull["base"]["sha"]
        base_ref = pull["base"]["ref"]
        state = pull["state"]
    except (KeyError, TypeError) as error:
        raise ReviewError("GitHub returned incomplete pull request metadata.") from error
    if state != "open":
        raise ReviewError("Only an open pull request can receive a review gate.")
    if current_head != head or current_base != base:
        raise ReviewError("PR head or base changed; review the current diff first.")
    if not isinstance(base_ref, str) or not base_ref:
        raise ReviewError("GitHub returned an invalid base branch.")
    # PR metadata can briefly retain an old base SHA after another merge.
    ref = api("GET", f"repos/{repo}/git/ref/heads/{quote(base_ref, safe='/')}", None)
    branch_object = ref.get("object")
    if not isinstance(branch_object, dict) or branch_object.get("sha") != base:
        raise ReviewError("The base branch advanced; review against its current commit.")
    return base_ref


def publish_review(
    api: Api,
    repo: str,
    number: int,
    head: str,
    base: str,
    result: str,
    report: str,
) -> str:
    if not REPO_PATTERN.fullmatch(repo) or number < 1:
        raise ReviewError("Supply an owner/repository and a positive PR number.")
    if not SHA_PATTERN.fullmatch(head) or not SHA_PATTERN.fullmatch(base):
        raise ReviewError("Expected head and base must be full lowercase commit SHAs.")
    if result not in {"pass", "fail"} or not report.strip():
        raise ReviewError("Supply a pass/fail result and a nonempty completed review.")

    base_ref = validate_commit(api, repo, number, head, base)
    context = f"{CONTEXT}/{base_ref}"
    status_path = f"repos/{repo}/statuses/{head}"
    try:
        api("POST", status_path, {
            "state": "pending", "context": context,
            "description": "Agent review is being recorded",
        })
        review = api("POST", f"repos/{repo}/pulls/{number}/reviews", {
            "commit_id": head,
            "event": "COMMENT",
            "body": (
                f"Agent review: **{result.upper()}**\n\n"
                f"Reviewed head: `{head}`\n\nReviewed base: `{base}` ({base_ref})\n\n"
                "This is an agent review record, not an independent GitHub approval.\n\n"
                + report.strip()
            ),
        })
        url = review.get("html_url")
        if not isinstance(url, str) or urlparse(url).scheme != "https" or not urlparse(url).netloc:
            raise ReviewError("GitHub did not return a valid published review URL.")
        if validate_commit(api, repo, number, head, base) != base_ref:
            raise ReviewError("PR target branch changed; review the current diff first.")
        api("POST", status_path, {
            "state": "success" if result == "pass" else "failure",
            "context": context,
            "description": (
                "Agent review passed for this commit" if result == "pass"
                else "Agent review found blocking issues"
            ),
            "target_url": url,
        })
        return url
    except ReviewError as error:
        try:
            api("POST", status_path, {
                "state": "error", "context": context,
                "description": "Review publication or commit validation failed",
            })
        except ReviewError as status_error:
            raise ReviewError(f"{error} Also could not mark the gate as error: {status_error}") from error
        raise


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("number", type=int, help="Open pull request number")
    parser.add_argument("--repo", required=True, help="GitHub owner/repository")
    parser.add_argument("--expected-head", required=True)
    parser.add_argument("--expected-base", required=True)
    parser.add_argument("--result", choices=["pass", "fail"], required=True)
    parser.add_argument("--body-file", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        report = args.body_file.read_text(encoding="utf-8")
        url = publish_review(
            gh_api, args.repo, args.number, args.expected_head, args.expected_base,
            args.result, report,
        )
    except (OSError, ReviewError) as error:
        print(f"Agent review: {error}", file=sys.stderr)
        return 2
    print(url)
    return 0 if args.result == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
