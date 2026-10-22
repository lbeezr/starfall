import contextlib
import copy
import io
import json
from pathlib import Path
import tempfile
import unittest

from agent_factory import audit_closure, catalog, main, next_tasks, validate_plan


def task(key, writes, depends=(), resources=()):
    return {'id': key, 'writes': writes, 'depends_on': list(depends),
            'resources': list(resources), 'acceptance': ['Observable outcome'],
            'checks': ['Relevant behavioral check']}


def plan(*tasks):
    return {'version': 1, 'outcome': 'Ship a complete bounded change', 'tasks': list(tasks)}


def github(state='OPEN', issue_state='OPEN', reason=None, base='main'):
    return {'data': {'repository': {'nameWithOwner': 'lbeezr/starfall',
            'defaultBranchRef': {'name': 'main'}, 'pullRequest': {
                'number': 7, 'state': state, 'mergedAt': '2026-10-22T12:00:00Z' if state == 'MERGED' else None,
                'baseRefName': base, 'closingIssuesReferences': {
                    'pageInfo': {'hasNextPage': False}, 'nodes': [
                        {'number': 4, 'state': issue_state, 'stateReason': reason,
                         'url': 'https://github.com/lbeezr/starfall/issues/4'}]}}}}}


class PlanningTests(unittest.TestCase):
    def test_diamond_releases_only_integrated_dependencies(self):
        document = plan(task('contract', ['docs/contract.md']),
                        task('core', ['Sources/'], ['contract']),
                        task('ui', ['App/'], ['contract']),
                        task('integrate', ['README.md'], ['core', 'ui']))
        self.assertEqual(next_tasks(document)['ready'], ['contract'])
        self.assertEqual(next_tasks(document, ['contract'])['ready'], ['core', 'ui'])
        result = next_tasks(document, ['contract', 'core'], ['ui'])
        self.assertFalse(result['ready'])
        self.assertIn('ui', result['waiting']['integrate'])
        self.assertEqual(next_tasks(document, ['contract', 'core', 'ui'])['ready'], ['integrate'])
        self.assertTrue(next_tasks(document, ['contract', 'core', 'ui', 'integrate'])['complete'])

    def test_conflicting_writers_require_real_order_including_transitive_order(self):
        for first, second in [('App/', 'App/View.swift'), ('App/View.swift', 'App/View.swift')]:
            with self.subTest(first=first), self.assertRaisesRegex(ValueError, 'unordered writers'):
                validate_plan(plan(task('one', [first]), task('two', [second])))
        validate_plan(plan(task('one', ['App/']), task('middle', ['docs/'], ['one']),
                           task('two', ['App/View.swift'], ['middle'])))
        validate_plan(plan(task('one', ['App/']), task('two', ['AppTests/'])))

    def test_bad_graphs_and_ambiguous_paths_fail(self):
        documents = [plan(task('one', [], ['missing'])),
                     plan(task('one', [], ['two']), task('two', [], ['one'])),
                     plan(task('one', []), task('one', []))]
        documents.extend(plan(task('one', [path])) for path in
                         ['../App', '/App', 'App/../Tests', 'App//View', './App',
                          'App/*.swift', '.git/config', 'App\\View'])
        for document in documents:
            with self.subTest(document=document), self.assertRaises(ValueError):
                validate_plan(document)

    def test_resources_and_wip_count_handoffs_until_integrated(self):
        document = plan(task('one', ['App/'], resources=['simulator']),
                        task('two', ['UITests/'], resources=['simulator']),
                        task('three', ['docs/']))
        self.assertEqual(next_tasks(document)['ready'], ['one', 'three'])
        result = next_tasks(document, active=['one'], limit=1)
        self.assertFalse(result['ready'])
        self.assertEqual(result['waiting']['two'], 'exclusive resource busy')
        self.assertEqual(next_tasks(document, ['one'])['ready'], ['two', 'three'])
        with self.assertRaises(ValueError):
            next_tasks(document, active=['one', 'two'])

    def test_invalid_completion_claims_and_shared_leaf_issues_fail(self):
        document = plan(task('one', []), task('two', [], ['one']))
        for integrated, active, limit in [(['two'], [], 3), ([], ['two'], 3),
                                          (['one'], ['one'], 3), (['missing'], [], 3),
                                          ([], [], 0), ([], ['one'], 0)]:
            with self.subTest(integrated=integrated, active=active), self.assertRaises(ValueError):
                next_tasks(document, integrated, active, limit)
        for row in document['tasks']:
            row['issue'] = 4
        with self.assertRaisesRegex(ValueError, 'unique positive leaf'):
            validate_plan(document)


class ClosureTests(unittest.TestCase):
    def test_open_pr_predicts_closure_without_claiming_completion(self):
        result = audit_closure(github(), [4])
        self.assertEqual(result['phase'], 'ready-to-close-on-merge')
        self.assertIn('not inspected', result['project_status'])

    def test_only_merged_and_completed_issue_counts(self):
        self.assertEqual(audit_closure(github('MERGED', 'CLOSED', 'COMPLETED'), [4])['phase'], 'completed')
        for state, reason in [('OPEN', None), ('CLOSED', 'NOT_PLANNED'), ('CLOSED', None)]:
            self.assertEqual(audit_closure(github('MERGED', state, reason), [4])['phase'], 'needs-attention')
        self.assertEqual(audit_closure(github('CLOSED'), [4])['phase'], 'needs-attention')

    def test_wrong_base_missing_links_and_cross_repo_number_collisions(self):
        self.assertTrue(audit_closure(github(base='feature'), [4])['problems'])
        self.assertTrue(audit_closure(github(), [5])['problems'])
        document = github()
        document['data']['repository']['pullRequest']['closingIssuesReferences']['nodes'][0]['url'] = 'https://github.com/other/repo/issues/4'
        self.assertTrue(audit_closure(document, [4])['problems'])

    def test_truncated_and_failed_queries_are_unknown(self):
        document = github()
        document['data']['repository']['pullRequest']['closingIssuesReferences']['pageInfo']['hasNextPage'] = True
        for snapshot in [document, {'errors': [{'message': 'denied'}]}]:
            with self.assertRaises(ValueError):
                audit_closure(snapshot, [4])

    def test_extra_closing_links_cannot_silently_close_unplanned_work(self):
        document = github()
        nodes = document['data']['repository']['pullRequest']['closingIssuesReferences']['nodes']
        nodes.append({'number': 5, 'state': 'OPEN', 'stateReason': None,
                      'url': 'https://github.com/lbeezr/starfall/issues/5'})
        self.assertTrue(audit_closure(document, [4])['problems'])
        self.assertFalse(audit_closure(document, [4, 5])['problems'])

    def test_cli_exit_codes_and_read_only_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'snapshot.json'
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                for document, expected in [(github(), 0), (github('CLOSED'), 1), ({}, 2)]:
                    content = json.dumps(document)
                    path.write_text(content)
                    self.assertEqual(main(['closure', str(path), '--issue', '4']), expected)
                    self.assertEqual(path.read_text(), content)
                content = json.dumps(plan(task('one', [])))
                path.write_text(content)
                self.assertEqual(main(['plan', str(path)]), 0)
                self.assertEqual(path.read_text(), content)

    def test_merged_timestamp_and_expected_issues_are_required(self):
        document = copy.deepcopy(github('MERGED', 'CLOSED', 'COMPLETED'))
        document['data']['repository']['pullRequest']['mergedAt'] = None
        with self.assertRaises(ValueError):
            audit_closure(document, [4])
        for expected in [[], [0], [True]]:
            with self.assertRaises(ValueError):
                audit_closure(github(), expected)


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.document = json.loads((Path(__file__).resolve().parents[1] /
                                    '.github/game-workstreams.json').read_text())

    def test_real_catalog_exports_only_available_labels_and_primary_mobile_platforms(self):
        summary = catalog(self.document)
        self.assertEqual(summary['primary_platforms'], ['ios', 'ipados'])
        self.assertEqual(summary['deferred_platforms'], ['macos'])
        labels = catalog(self.document, 'labels')
        names = {label['name'] for label in labels}
        self.assertIn('workstream:ui-ux', names)
        self.assertIn('workstream:accessibility', names)
        self.assertNotIn('platform:macos', names)
        self.assertNotIn('workstream:commerce', names)
        self.assertNotIn('workstream:online-services', names)
        self.assertNotIn('workstream:multiplayer', names)
        self.assertFalse(any(name.startswith('role:') for name in names))

    def test_every_role_has_one_primary_home_and_duplicate_labels_fail(self):
        document = copy.deepcopy(self.document)
        document['workstreams'][1]['roles'].append(document['workstreams'][0]['roles'][0].upper())
        with self.assertRaisesRegex(ValueError, 'primary home'):
            catalog(document)
        document = copy.deepcopy(self.document)
        document['labels'].append(document['labels'][0])
        with self.assertRaises(ValueError):
            catalog(document)

    def test_generated_catalog_is_reproducible_and_covers_every_named_role(self):
        generated = catalog(self.document, 'markdown')
        path = Path(__file__).resolve().parents[1] / 'docs/GAME_ROLE_CATALOG.md'
        self.assertEqual(path.read_text(), generated)
        for stream in self.document['workstreams']:
            self.assertIn(stream['title'], generated)
            for role in stream['roles']:
                self.assertIn(role, generated)


if __name__ == '__main__':
    unittest.main()
