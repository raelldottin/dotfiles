from __future__ import annotations

import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from typing import Any

from agent_review import ReviewError, gh_api, main, publish_review


HEAD = "a" * 40
BASE = "b" * 40
NEW = "c" * 40
REPO = "example/dotfiles"
URL = "https://github.com/example/dotfiles/pull/7#pullrequestreview-1"


class FakeApi:
    def __init__(self) -> None:
        self.head = HEAD
        self.base = BASE
        self.branch = BASE
        self.state = "open"
        self.base_ref = "dev"
        self.change_after_review: str | None = None
        self.fail_review = False
        self.fail_error_status = False
        self.fail_pending_status = False
        self.effective_status = "success"
        self.url = URL
        self.calls: list[tuple[str, str, dict[str, Any] | None]] = []

    def __call__(self, method: str, path: str, payload: dict[str, Any] | None) -> dict[str, Any]:
        self.calls.append((method, path, payload))
        if method == "GET" and path.endswith("/pulls/7"):
            return {"state": self.state, "head": {"sha": self.head},
                    "base": {"sha": self.base, "ref": self.base_ref}}
        if method == "GET" and "/git/ref/" in path:
            return {"object": {"sha": self.branch}}
        if path.endswith("/reviews"):
            if self.fail_review:
                raise ReviewError("Review API unavailable")
            if self.change_after_review == "head":
                self.head = NEW
            if self.change_after_review == "base":
                self.branch = NEW
            if self.change_after_review == "target":
                self.base_ref = "main"
            return {"html_url": self.url}
        if "/statuses/" in path and payload is not None:
            if self.fail_pending_status and payload["state"] == "pending":
                raise ReviewError("Transient pending status failure")
            if self.fail_error_status and payload["state"] == "error":
                raise ReviewError("Status API unavailable")
            self.effective_status = payload["state"]
            return {"state": payload["state"]}
        raise AssertionError(f"Unexpected API call: {method} {path}")

    def statuses(self) -> list[dict[str, Any]]:
        return [payload for _, path, payload in self.calls
                if "/statuses/" in path and payload is not None]


class AgentReviewTests(unittest.TestCase):
    def publish(self, api: FakeApi, result: str = "pass", report: str = "No actionable findings.") -> str:
        return publish_review(api, REPO, 7, HEAD, BASE, result, report)

    def test_pass_records_comment_then_commit_specific_success(self) -> None:
        api = FakeApi()
        self.assertEqual(self.publish(api), URL)
        self.assertEqual([s["state"] for s in api.statuses()], ["pending", "success"])
        posts = [(path, payload) for method, path, payload in api.calls if method == "POST"]
        self.assertTrue(posts[0][0].endswith("/statuses/" + HEAD))
        self.assertTrue(posts[1][0].endswith("/pulls/7/reviews"))
        assert posts[1][1] is not None
        self.assertEqual(posts[1][1]["event"], "COMMENT")
        self.assertEqual(posts[1][1]["commit_id"], HEAD)
        self.assertIn(BASE, posts[1][1]["body"])
        self.assertEqual(api.statuses()[-1]["target_url"], URL)
        self.assertEqual(api.statuses()[-1]["context"], "agent-review/dev")

    def test_identical_head_targeting_different_branches_has_separate_gates(self) -> None:
        contexts = []
        for branch in ["main", "dev"]:
            api = FakeApi()
            api.base_ref = branch
            self.publish(api)
            contexts.append(api.statuses()[-1]["context"])
        self.assertEqual(contexts, ["agent-review/main", "agent-review/dev"])

    def test_pending_failure_attempts_to_invalidate_previous_success(self) -> None:
        api = FakeApi()
        api.fail_pending_status = True
        with self.assertRaisesRegex(ReviewError, "Transient pending status failure"):
            self.publish(api, "fail", "Blocking findings.")
        self.assertEqual([s["state"] for s in api.statuses()], ["pending", "error"])
        self.assertEqual(api.effective_status, "error")
        self.assertFalse(any(path.endswith("/reviews") for _, path, _ in api.calls))

    def test_blocking_findings_record_failure(self) -> None:
        api = FakeApi()
        self.publish(api, "fail", "Blocking issue: unsafe write.")
        self.assertEqual([s["state"] for s in api.statuses()], ["pending", "failure"])

    def test_stale_head_or_base_stops_before_any_write(self) -> None:
        for field in ["head", "base", "branch"]:
            with self.subTest(field=field):
                api = FakeApi()
                setattr(api, field, NEW)
                with self.assertRaises(ReviewError):
                    self.publish(api)
                self.assertFalse(any(method == "POST" for method, _, _ in api.calls))

    def test_closed_pull_request_stops_before_any_write(self) -> None:
        api = FakeApi()
        api.state = "closed"
        with self.assertRaises(ReviewError):
            self.publish(api)
        self.assertFalse(api.statuses())

    def test_head_or_base_advancing_during_review_never_passes(self) -> None:
        for field in ["head", "base", "target"]:
            with self.subTest(field=field):
                api = FakeApi()
                api.change_after_review = field
                with self.assertRaises(ReviewError):
                    self.publish(api)
                self.assertEqual([s["state"] for s in api.statuses()], ["pending", "error"])

    def test_publication_failure_invalidates_previous_gate(self) -> None:
        api = FakeApi()
        api.fail_review = True
        with self.assertRaisesRegex(ReviewError, "Review API unavailable"):
            self.publish(api)
        self.assertEqual([s["state"] for s in api.statuses()], ["pending", "error"])

    def test_invalid_review_url_cannot_pass(self) -> None:
        api = FakeApi()
        api.url = "javascript:alert(1)"
        with self.assertRaises(ReviewError):
            self.publish(api)
        self.assertEqual(api.statuses()[-1]["state"], "error")

    def test_failure_to_record_error_is_reported(self) -> None:
        api = FakeApi()
        api.fail_review = True
        api.fail_error_status = True
        with self.assertRaisesRegex(ReviewError, "could not mark the gate as error"):
            self.publish(api)
        self.assertNotIn("success", [s["state"] for s in api.statuses()])

    def test_empty_report_or_invalid_input_never_calls_github(self) -> None:
        api = FakeApi()
        for repo, number, head, base, result, report in [
            (REPO, 7, HEAD, BASE, "pass", "  "),
            (REPO, 7, HEAD, BASE, "unknown", "Report"),
            (REPO, 7, "short", BASE, "pass", "Report"),
            (REPO, 7, HEAD, "short", "pass", "Report"),
            (REPO, 0, HEAD, BASE, "pass", "Report"),
            ("invalid/repo/path", 7, HEAD, BASE, "pass", "Report"),
        ]:
            with self.subTest(repo=repo, number=number, head=head, base=base, result=result):
                with self.assertRaises(ReviewError):
                    publish_review(api, repo, number, head, base, result, report)
        self.assertFalse(api.calls)

    def test_malformed_live_branch_metadata_stops_before_writes(self) -> None:
        api = FakeApi()

        def malformed(method: str, path: str, payload: dict[str, Any] | None) -> dict[str, Any]:
            response = api(method, path, payload)
            return {"object": "invalid"} if "/git/ref/" in path else response

        with self.assertRaises(ReviewError):
            publish_review(malformed, REPO, 7, HEAD, BASE, "pass", "Review")
        self.assertFalse(api.statuses())

    def test_cli_exit_codes_distinguish_pass_findings_and_errors(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            report = Path(folder) / "review.md"
            report.write_text("Completed review.", encoding="utf-8")
            for result, expected, fail_api in [("pass", 0, False), ("fail", 1, False), ("pass", 2, True)]:
                with self.subTest(result=result, fail_api=fail_api):
                    api = FakeApi()
                    api.fail_review = fail_api
                    with patch("agent_review.gh_api", api), patch("sys.stdout", io.StringIO()), patch("sys.stderr", io.StringIO()):
                        code = main(["7", "--repo", REPO, "--expected-head", HEAD,
                                     "--expected-base", BASE, "--result", result,
                                     "--body-file", str(report)])
                    self.assertEqual(code, expected)

    def test_json_transport_preserves_literal_review_content(self) -> None:
        payload = {"body": 'Quoted "text", newlines\n`literal` $(literal)'}
        response = subprocess.CompletedProcess(["gh"], 0, '{"id": 1}', "")
        with patch("agent_review.subprocess.run", return_value=response) as run:
            self.assertEqual(gh_api("POST", "repos/example/dotfiles/pulls/7/reviews", payload), {"id": 1})
        args, kwargs = run.call_args
        self.assertIsInstance(args[0], list)
        self.assertEqual(args[0][-2:], ["--input", "-"])
        self.assertEqual(json.loads(kwargs["input"]), payload)
        self.assertNotIn("shell", kwargs)

    def test_transport_errors_are_not_valid_review_responses(self) -> None:
        for response in ["not json", "[]"]:
            with self.subTest(response=response):
                process = subprocess.CompletedProcess(["gh"], 0, response, "")
                with patch("agent_review.subprocess.run", return_value=process):
                    with self.assertRaises(ReviewError):
                        gh_api("GET", "repos/example/dotfiles/pulls/7", None)
        failure = subprocess.CalledProcessError(403, ["gh"], stderr="Permission denied")
        with patch("agent_review.subprocess.run", side_effect=failure):
            with self.assertRaisesRegex(ReviewError, "Permission denied"):
                gh_api("POST", "repos/example/dotfiles/statuses/" + HEAD, {})


if __name__ == "__main__":
    unittest.main()
