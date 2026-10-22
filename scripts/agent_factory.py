#!/usr/bin/env python3
"""Offline planning and GitHub closure diagnostics; never dispatch or mutate work."""
import argparse
import itertools
import json
from pathlib import Path
import re
import sys


def strings(value, label, *, empty=True):
    if (not isinstance(value, list) or any(not isinstance(item, str) or not item.strip()
                                           for item in value)
            or len(value) != len(set(value)) or (not empty and not value)):
        raise ValueError(f'{label}: expected unique nonempty strings')
    return value


def owned_path(value):
    # Literal repo-relative files/subtrees only: ambiguous globs hide collisions.
    parts = value.rstrip('/').split('/')
    if (any(part in {'', '.', '..'} for part in parts) or value.startswith('/')
            or any(char in value for char in '\\*?[]') or parts[0] == '.git'):
        raise ValueError(f'invalid write path: {value}')
    return '/'.join(parts)


def overlap(left, right):
    return left == right or left.startswith(right + '/') or right.startswith(left + '/')


def validate_plan(document):
    if (not isinstance(document, dict) or type(document.get('version')) is not int
            or document['version'] != 1):
        raise ValueError('plan requires version 1')
    if not isinstance(document.get('outcome'), str) or not document['outcome'].strip():
        raise ValueError('plan requires an observable outcome')
    rows = document.get('tasks')
    if not isinstance(rows, list) or not rows:
        raise ValueError('plan requires tasks')
    tasks = {}
    issues = set()
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError('each task must be an object')
        key = row.get('id')
        if not isinstance(key, str) or not re.fullmatch(r'[a-z][a-z0-9-]*', key):
            raise ValueError('task id must be a lowercase slug')
        if key in tasks:
            raise ValueError(f'duplicate task: {key}')
        task = dict(row)
        task['depends_on'] = strings(row.get('depends_on', []), f'{key}.depends_on')
        task['writes'] = [owned_path(path) for path in strings(row.get('writes'), f'{key}.writes')]
        task['resources'] = strings(row.get('resources', []), f'{key}.resources')
        strings(row.get('acceptance'), f'{key}.acceptance', empty=False)
        strings(row.get('checks'), f'{key}.checks', empty=False)
        issue = row.get('issue')
        if issue is not None:
            if type(issue) is not int or issue < 1 or issue in issues:
                raise ValueError(f'{key}: issue must be a unique positive leaf issue number')
            issues.add(issue)
        tasks[key] = task

    ancestors = {}
    visiting = set()

    def visit(key):
        if key in visiting:
            raise ValueError(f'dependency cycle at {key}')
        if key not in tasks:
            raise ValueError(f'unknown dependency: {key}')
        if key not in ancestors:
            visiting.add(key)
            dependencies = set()
            for dependency in tasks[key]['depends_on']:
                dependencies.add(dependency)
                dependencies.update(visit(dependency))
            visiting.remove(key)
            ancestors[key] = dependencies
        return ancestors[key]

    for key in tasks:
        visit(key)
    for left, right in itertools.combinations(tasks, 2):
        if left in ancestors[right] or right in ancestors[left]:
            continue
        for first, second in itertools.product(tasks[left]['writes'], tasks[right]['writes']):
            if overlap(first, second):
                raise ValueError(f'unordered writers {left}/{right}: {first} overlaps {second}; '
                                 'assign one owner or add a real dependency')
    return tasks, ancestors


def next_tasks(document, integrated=(), active=(), limit=3):
    tasks, ancestors = validate_plan(document)
    integrated, active = set(integrated), set(active)
    unknown = (integrated | active) - tasks.keys()
    if unknown or integrated & active or limit < 1 or len(active) > limit:
        raise ValueError('invalid integrated/active task ids or worker limit')
    for key in integrated | active:
        if not ancestors[key] <= integrated:
            raise ValueError(f'{key}: dependencies are not integrated')
    resources = {resource for key in active for resource in tasks[key]['resources']}
    if sum(len(tasks[key]['resources']) for key in active) != len(resources):
        raise ValueError('active tasks reserve the same exclusive resource')
    selected, waiting = [], {}
    for key, task in tasks.items():
        if key in integrated or key in active:
            continue
        missing = ancestors[key] - integrated
        if missing:
            waiting[key] = 'depends on ' + ', '.join(sorted(missing))
        elif resources & set(task['resources']):
            waiting[key] = 'exclusive resource busy'
        elif len(active) + len(selected) >= limit:
            waiting[key] = 'worker/WIP limit'
        else:
            selected.append(key)
            resources.update(task['resources'])
    return {'ready': selected, 'active': sorted(active), 'integrated': sorted(integrated),
            'waiting': waiting, 'complete': len(integrated) == len(tasks)}


def audit_closure(snapshot, expected):
    """Consume the exact GraphQL selection documented in AGENT_FACTORY.md."""
    if snapshot.get('errors'):
        raise ValueError('GitHub returned GraphQL errors; completion is unknown')
    repository = snapshot['data']['repository']
    name = repository['nameWithOwner']
    default = repository['defaultBranchRef']['name']
    pr = repository['pullRequest']
    references = pr['closingIssuesReferences']
    if references['pageInfo']['hasNextPage']:
        raise ValueError('closing issue references are truncated; completion is unknown')
    if not expected or any(type(number) is not int or number < 1 for number in expected):
        raise ValueError('supply the expected leaf issue numbers with --issue')
    # Check URLs too: issue numbers alone collide across repositories.
    linked = {node['number']: node for node in references['nodes']
              if node['url'] == f'https://github.com/{name}/issues/{node["number"]}'}
    problems = []
    expected_urls = {f'https://github.com/{name}/issues/{number}' for number in expected}
    for issue in references['nodes']:
        if issue['url'] not in expected_urls:
            problems.append(f'unexpected closing link: {issue["url"]}; confirm it is fully '
                            'resolved and include it in the expected issue set, or remove the link')
    if pr['baseRefName'] != default:
        problems.append(f'PR targets {pr["baseRefName"]}, not default branch {default}')
    merged = pr['state'] == 'MERGED' and bool(pr['mergedAt'])
    if pr['state'] not in {'OPEN', 'MERGED'}:
        problems.append('PR closed without merge; its task is not completed')
    if pr['state'] == 'MERGED' and not merged:
        raise ValueError('merged PR has no merge timestamp; completion is unknown')
    for number in sorted(set(expected)):
        issue = linked.get(number)
        if issue is None:
            problems.append(f'#{number}: missing native closing link; put Closes #{number} '
                            'in the PR description before merge')
        elif merged and (issue['state'] != 'CLOSED' or issue['stateReason'] != 'COMPLETED'):
            problems.append(f'#{number}: merged PR has not completed this issue; '
                            'verify acceptance and reconcile explicitly')
    return {'phase': 'needs-attention' if problems else
            ('completed' if merged else 'ready-to-close-on-merge'),
            'repository': name, 'pr': pr['number'], 'expected_issues': sorted(set(expected)),
            'problems': problems,
            'project_status': 'not inspected; verify the project Item closed workflow'}


def catalog(document, output='summary'):
    if type(document.get('version')) is not int or document['version'] != 1:
        raise ValueError('catalog requires version 1')
    if not isinstance(document.get('workstreams'), list) or not document['workstreams']:
        raise ValueError('catalog requires workstreams')
    scopes = {'available', 'future', 'excluded'}
    streams, roles, labels, ids = [], set(), [], set()
    for stream in document['workstreams']:
        key = stream['id']
        if not re.fullmatch(r'[a-z][a-z0-9-]*', key) or key in ids or stream['scope'] not in scopes:
            raise ValueError('invalid/duplicate workstream id or scope')
        ids.add(key)
        for role in strings(stream['roles'], f'{key}.roles', empty=False):
            normalized = role.casefold()
            if normalized in roles:
                raise ValueError(f'role has more than one primary home: {role}')
            roles.add(normalized)
        if not stream['title'].strip() or not stream['description'].strip():
            raise ValueError('workstream needs a title and purpose')
        streams.append(stream)
        if stream['scope'] == 'available':
            labels.append({'name': f'workstream:{key}', 'color': '0052CC',
                           'description': stream['description']})
    for label in document['labels']:
        if label['scope'] not in scopes:
            raise ValueError('invalid label scope')
        if label['scope'] == 'available':
            labels.append({key: label[key] for key in ['name', 'color', 'description']})
    names = set()
    for label in labels:
        if (label['name'] in names or len(label['name']) > 50
                or not re.fullmatch(r'[0-9A-Fa-f]{6}', label['color'])
                or len(label['description']) > 100):
            raise ValueError('invalid/duplicate label name, color or description')
        names.add(label['name'])
    primary = strings(document['primary_platforms'], 'primary_platforms', empty=False)
    deferred = strings(document['deferred_platforms'], 'deferred_platforms')
    if set(primary) & set(deferred):
        raise ValueError('platform cannot be primary and deferred')
    if output == 'labels':
        return labels
    if output == 'markdown':
        lines = ['# Game development role catalogue', '',
                 'Generated from [.github/game-workstreams.json](../.github/game-workstreams.json) '
                 'with `python3 scripts/agent_factory.py catalog .github/game-workstreams.json --format markdown`. '
                 'Edit the source, then regenerate this file.', '',
                 f'{len(streams)} workstreams; {len(roles)} functional roles. '
                 'This is a coverage inventory, not a staffing or feature commitment. '
                 'See [the tracking contract](GAME_WORKSTREAMS.md) for applicability, labels and gaps.', '',
                 '| Primary workstream | Scope | Roles and specialist responsibilities |',
                 '| --- | --- | --- |']
        lines.extend(f'| {stream["title"]} (`{stream["id"]}`) | {stream["scope"]} | '
                     + '; '.join(stream['roles']) + ' |' for stream in streams)
        return '\n'.join(lines) + '\n'
    return {'workstreams': len(streams), 'roles': len(roles), 'available_labels': len(labels),
            'primary_platforms': primary, 'deferred_platforms': deferred,
            'scope_counts': {scope: sum(stream['scope'] == scope for stream in streams)
                             for scope in sorted(scopes)}}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    plan = commands.add_parser('plan', help='validate ownership/DAG and suggest the next dispatch')
    plan.add_argument('snapshot', type=Path)
    plan.add_argument('--integrated', action='append', default=[])
    plan.add_argument('--active', action='append', default=[], help='includes awaiting integration')
    plan.add_argument('--limit', type=int, default=3)
    closure = commands.add_parser('closure', help='audit native closing links and merged issue states')
    closure.add_argument('snapshot', type=Path)
    closure.add_argument('--issue', type=int, action='append', required=True)
    inventory = commands.add_parser('catalog', help='validate role coverage and export optional labels')
    inventory.add_argument('snapshot', type=Path)
    inventory.add_argument('--format', choices=['summary', 'labels', 'markdown'], default='summary')
    args = parser.parse_args(argv)
    try:
        document = json.loads(args.snapshot.read_text())
        if args.command == 'plan':
            result = next_tasks(document, args.integrated, args.active, args.limit)
        elif args.command == 'closure':
            result = audit_closure(document, args.issue)
        else:
            result = catalog(document, args.format)
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 2
    print(result if isinstance(result, str) else json.dumps(result, indent=2),
          end='' if isinstance(result, str) else '\n')
    return 1 if isinstance(result, dict) and result.get('problems') else 0


if __name__ == '__main__':
    sys.exit(main())
