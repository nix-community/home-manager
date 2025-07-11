#!/usr/bin/env python3
"""
Manage pull request reviewers for Home Manager.

This script handles the reviewer management logic from the tag-maintainers workflow,
including checking for manually requested reviewers and managing removals.
"""

import argparse
import json
import logging
import subprocess
import sys
from typing import Final

# Configure logging to output to stderr
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    stream=sys.stderr,
)

MANUAL_REVIEW_REQUEST_QUERY: Final[str] = """
query($owner: String!, $repo: String!, $prNumber: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $prNumber) {
      timelineItems(first: 100, itemTypes: [REVIEW_REQUESTED_EVENT]) {
        nodes {
          ... on ReviewRequestedEvent {
            actor {
              __typename
              login
            }
            requestedReviewer {
              ... on User { login }
              ... on Bot { login }
            }
          }
        }
      }
    }
  }
}
"""


class GHError(Exception):
    """Custom exception for errors related to 'gh' CLI commands."""
    pass


def run_gh_command(args: list[str], input_data: str | None = None) -> str:
    """Runs a GitHub CLI command and returns its stdout."""
    command = ["gh"] + args
    try:
        result = subprocess.run(
            command,
            input=input_data,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        logging.error("Error running command: %s", " ".join(command))
        logging.error("Stderr: %s", e.stderr.strip())
        raise GHError(f"Failed to execute gh command: {e}") from e


def get_manually_requested_reviewers(
    owner: str, repo: str, pr_number: int
) -> set[str]:
    """Fetches a set of reviewers who were manually requested by a human."""
    try:
        result = run_gh_command([
            "api", "graphql",
            "-f", f"query={MANUAL_REVIEW_REQUEST_QUERY}",
            "-F", f"owner={owner}",
            "-F", f"repo={repo}",
            "-F", f"prNumber={pr_number}",
        ])
        data = json.loads(result)
        nodes = data.get("data", {}).get("repository", {}).get("pullRequest", {}).get("timelineItems", {}).get("nodes", [])

        manually_requested = {
            node["requestedReviewer"]["login"]
            for node in nodes
            if node and node.get("actor", {}).get("__typename") == "User" and node.get("requestedReviewer")
        }
        return manually_requested
    except (GHError, json.JSONDecodeError, KeyError) as e:
        logging.error("Could not determine manually requested reviewers: %s", e)
        return set()


def get_users_from_gh(args: list[str], error_message: str) -> set[str]:
    """A generic helper to get a set of users from a 'gh' command."""
    try:
        result = run_gh_command(args)
        return {user.strip() for user in result.split("\n") if user.strip()}
    except GHError as e:
        logging.error("%s: %s", error_message, e)
        return set()


def get_pending_reviewers(pr_number: int) -> set[str]:
    """Gets the set of currently pending reviewers for a PR."""
    return get_users_from_gh(
        ["pr", "view", str(pr_number), "--json", "reviewRequests", "--jq", ".reviewRequests[].login"],
        "Error getting pending reviewers",
    )


def get_past_reviewers(owner: str, repo: str, pr_number: int) -> set[str]:
    """Gets the set of users who have already reviewed the PR."""
    return get_users_from_gh(
        ["api", f"repos/{owner}/{repo}/pulls/{pr_number}/reviews", "--jq", ".[].user.login"],
        "Error getting past reviewers",
    )


def is_collaborator(owner: str, repo: str, username: str) -> bool:
    """Checks if a user is a collaborator on the repository."""
    try:
        # The `--silent` flag makes `gh` exit with 0 on success (2xx) and 1 on error (e.g., 404)
        run_gh_command(["api", f"repos/{owner}/{repo}/collaborators/{username}", "--silent"])
        return True
    except GHError:
        # A non-zero exit code (GHError) implies the user is not a collaborator (404) or another issue.
        return False


def update_reviewers(
    pr_number: int,
    reviewers_to_add: set[str] | None = None,
    reviewers_to_remove: set[str] | None = None,
    owner: str | None = None,
    repo: str | None = None,
) -> None:
    """Adds or removes reviewers from a PR in a single operation per action."""
    if reviewers_to_add:
        logging.info("Requesting reviews from: %s", ", ".join(reviewers_to_add))
        try:
            run_gh_command([
                "pr", "edit", str(pr_number),
                "--add-reviewer", ",".join(reviewers_to_add)
            ])
        except GHError as e:
            logging.error("Failed to add reviewers: %s", e)

    if reviewers_to_remove and owner and repo:
        logging.info("Removing review requests from: %s", ", ".join(reviewers_to_remove))
        payload = json.dumps({"reviewers": list(reviewers_to_remove)})
        try:
            run_gh_command(
                [
                    "api", "--method", "DELETE",
                    f"repos/{owner}/{repo}/pulls/{pr_number}/requested_reviewers",
                    "--input", "-",
                ],
                input_data=payload,
            )
        except GHError as e:
            logging.error("Failed to remove reviewers: %s", e)


def main() -> None:
    """Main function to handle command-line arguments and manage reviewers."""
    parser = argparse.ArgumentParser(description="Manage pull request reviewers for Home Manager.")
    parser.add_argument("--owner", required=True, help="Repository owner.")
    parser.add_argument("--repo", required=True, help="Repository name.")
    parser.add_argument("--pr-number", type=int, required=True, help="Pull request number.")
    parser.add_argument("--pr-author", required=True, help="PR author's username.")
    parser.add_argument("--current-maintainers", default="", help="Space-separated list of current maintainers.")
    parser.add_argument("--no-module-files", action="store_true", help="Flag if no module files were changed.")
    args = parser.parse_args()

    # --- 1. Fetch current state from GitHub ---
    maintainers: set[str] = set(args.current_maintainers.split())
    pending_reviewers = get_pending_reviewers(args.pr_number)
    past_reviewers = get_past_reviewers(args.owner, args.repo, args.pr_number)
    manually_requested = get_manually_requested_reviewers(args.owner, args.repo, args.pr_number)

    logging.info("Current Maintainers: %s", ' '.join(maintainers) or "None")
    logging.info("Pending Reviewers: %s", ' '.join(pending_reviewers) or "None")
    logging.info("Past Reviewers: %s", ' '.join(past_reviewers) or "None")
    logging.info("Manually Requested: %s", ' '.join(manually_requested) or "None")

    # --- 2. Determine reviewers to remove ---
    reviewers_to_remove: set[str] = set()
    if args.no_module_files:
        reviewers_to_remove = pending_reviewers - manually_requested
        logging.info("No module files changed. Removing bot-requested reviewers.")
    else:
        outdated_reviewers = pending_reviewers - maintainers
        reviewers_to_remove = outdated_reviewers - manually_requested
        logging.info("Removing outdated bot-requested reviewers.")

    if reviewers_to_remove:
        update_reviewers(
            args.pr_number,
            owner=args.owner,
            repo=args.repo,
            reviewers_to_remove=reviewers_to_remove
        )
    else:
        logging.info("No reviewers to remove.")

    # --- 3. Determine new reviewers to add ---
    reviewers_to_add: set[str] = set()
    if not args.no_module_files and maintainers:
        users_to_exclude = {args.pr_author} | past_reviewers | pending_reviewers
        potential_reviewers = maintainers - users_to_exclude

        reviewers_to_add = {
            user for user in potential_reviewers if is_collaborator(args.owner, args.repo, user)
        }

        non_collaborators = potential_reviewers - reviewers_to_add
        if non_collaborators:
            logging.warning("Ignoring non-collaborators: %s", ", ".join(non_collaborators))


    if reviewers_to_add:
        update_reviewers(args.pr_number, reviewers_to_add=reviewers_to_add)
    else:
        logging.info("No new reviewers to add.")


if __name__ == "__main__":
    main()
