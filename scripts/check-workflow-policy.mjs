#!/usr/bin/env node

import { execFileSync } from 'node:child_process';
import {
  existsSync,
  lstatSync,
  readFileSync,
  readdirSync,
  realpathSync,
  statSync,
} from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { isDeepStrictEqual } from 'node:util';
import { parseDocument, visit } from 'yaml';

const scriptRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const root = realpathSync(resolve(process.argv[2] ?? scriptRoot));
const workflowsRoot = join(root, '.github', 'workflows');
const canonicalWorkflow = join(workflowsRoot, 'check.yml');
const maxYamlBytes = 1024 * 1024;
const maxYamlNodes = 50000;
const maxLocalReferences = 64;
const ambiguousWhitespace =
  /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f\u0080-\u009f\u00a0\u1680\u2000-\u200f\u2028-\u202f\u205f\u2060\u3000\ufeff]/u;
const remoteActionPattern = /^[^/@\s]+\/[^/@\s]+(?:\/[^@\s]+)?@[0-9a-f]{40}$/u;
const remoteReusablePattern =
  /^[^/@\s]+\/[^/@\s]+\/.github\/workflows\/[^@\s]+\.ya?ml@[^\s]+$/u;
const allowedRemoteActions = new Set([
  'actions/checkout',
  'github/codeql-action/upload-sarif',
]);
const supportedTags = new Set([
  'tag:yaml.org,2002:bool',
  'tag:yaml.org,2002:float',
  'tag:yaml.org,2002:int',
  'tag:yaml.org,2002:map',
  'tag:yaml.org,2002:null',
  'tag:yaml.org,2002:seq',
  'tag:yaml.org,2002:str',
]);
const canonicalContract = {
  name: 'Check',
  on: {
    pull_request: null,
    push: { branches: ['master'] },
    workflow_dispatch: null,
  },
  permissions: { contents: 'read' },
  concurrency: {
    group: 'check-${{ github.workflow }}-${{ github.ref }}',
    'cancel-in-progress': true,
  },
  jobs: {
    verify: {
      'runs-on': 'ubuntu-24.04',
      'timeout-minutes': 10,
      strategy: {
        'fail-fast': false,
        matrix: { 'node-version': [20, 22, 24] },
      },
      steps: [
        {
          name: 'Check out repository',
          uses: 'actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10',
          with: { 'persist-credentials': false },
        },
        {
          name: 'Set up Node.js',
          uses: 'actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e',
          with: {
            'node-version': '${{ matrix.node-version }}',
            cache: 'yarn',
            token: '',
          },
        },
        {
          name: 'Install dependencies',
          run: 'corepack yarn install --frozen-lockfile',
        },
        { name: 'Run full verification', run: 'make check' },
      ],
    },
  },
};

function reject(message) {
  console.error(message);
  process.exit(1);
}

function repositoryPath(path) {
  const repositoryRelativePath = relative(root, path);
  if (
    repositoryRelativePath === '' ||
    repositoryRelativePath === '..' ||
    repositoryRelativePath.startsWith(`..${sep}`)
  ) {
    reject(`local reference escapes the repository: ${path}`);
  }
  return repositoryRelativePath.split(sep).join('/');
}

const trackedPaths = new Set(
  execFileSync('git', ['-C', root, 'ls-files', '-z'], { encoding: 'utf8' })
    .split('\0')
    .filter(Boolean),
);

function assertNoSymlink(path) {
  const repositoryRelativePath = repositoryPath(path);
  let current = root;
  for (const component of repositoryRelativePath.split('/')) {
    current = join(current, component);
    if (existsSync(current) && lstatSync(current).isSymbolicLink()) {
      reject(
        `local references must not traverse symlinks: ${repositoryRelativePath}`,
      );
    }
  }
}

function requireTrackedFile(path) {
  const absolutePath = resolve(path);
  const repositoryRelativePath = repositoryPath(absolutePath);
  assertNoSymlink(absolutePath);
  if (!trackedPaths.has(repositoryRelativePath)) {
    reject(`local reference must be tracked: ${repositoryRelativePath}`);
  }
  if (!existsSync(absolutePath) || !statSync(absolutePath).isFile()) {
    reject(`local reference is not a file: ${repositoryRelativePath}`);
  }
  return absolutePath;
}

function workflowFiles(directory) {
  if (!existsSync(directory)) return [];
  return readdirSync(directory, { withFileTypes: true })
    .flatMap((entry) => {
      const path = join(directory, entry.name);
      if (entry.isSymbolicLink()) {
        reject(
          `local references must not traverse symlinks: ${repositoryPath(path)}`,
        );
      }
      return entry.isDirectory() ? workflowFiles(path) : [path];
    })
    .filter((path) => /\.ya?ml$/u.test(path))
    .sort();
}

function parseYaml(path) {
  const source = readFileSync(path, 'utf8');
  if (Buffer.byteLength(source) > maxYamlBytes) {
    reject(
      `workflow policy YAML exceeds ${maxYamlBytes} bytes: ${repositoryPath(path)}`,
    );
  }
  if (ambiguousWhitespace.test(source)) {
    reject(`ambiguous Unicode whitespace in ${repositoryPath(path)}`);
  }
  const document = parseDocument(source, {
    prettyErrors: false,
    strict: true,
    uniqueKeys: true,
  });
  if (document.errors.length > 0) {
    reject(
      `invalid workflow YAML in ${repositoryPath(path)}: ${document.errors[0].message}`,
    );
  }
  if (
    document.directives.yaml.explicit ||
    Object.keys(document.directives.tags).some((handle) => handle !== '!!')
  ) {
    reject(`YAML directives are forbidden in ${repositoryPath(path)}`);
  }
  let nodeCount = 0;
  visit(document, {
    Alias() {
      reject(`YAML aliases are forbidden in ${repositoryPath(path)}`);
    },
    Node(_key, node) {
      nodeCount += 1;
      if (nodeCount > maxYamlNodes) {
        reject(
          `workflow policy YAML exceeds ${maxYamlNodes} nodes: ${repositoryPath(path)}`,
        );
      }
      if (node.anchor) {
        reject(`YAML aliases are forbidden in ${repositoryPath(path)}`);
      }
      if (node.tag && !supportedTags.has(node.tag)) {
        reject(`unsupported YAML tag in ${repositoryPath(path)}: ${node.tag}`);
      }
    },
    Pair(_key, pair) {
      if (typeof pair.key?.value !== 'string') {
        reject(
          `workflow mapping keys must be strings in ${repositoryPath(path)}`,
        );
      }
      const key = pair.key.value;
      if (key.normalize('NFKC') !== key || ambiguousWhitespace.test(key)) {
        reject(`ambiguous workflow mapping key in ${repositoryPath(path)}`);
      }
      if (key === '<<') {
        reject(`YAML merge keys are forbidden in ${repositoryPath(path)}`);
      }
    },
  });
  if (document.warnings.length > 0) {
    reject(
      `invalid workflow YAML in ${repositoryPath(path)}: ${document.warnings[0].message}`,
    );
  }
  return document;
}

function documentValue(document) {
  return document.toJS({ maxAliasCount: 0 });
}

function walkValues(value, visitValue) {
  if (Array.isArray(value)) {
    for (const item of value) walkValues(item, visitValue);
  } else if (value !== null && typeof value === 'object') {
    for (const [key, item] of Object.entries(value)) {
      visitValue(key);
      walkValues(item, visitValue);
    }
  } else if (typeof value === 'string') {
    visitValue(value);
  }
}

function rejectCredentialExpressions(value, path) {
  walkValues(value, (text) => {
    if (/\$\{\{[\s\S]*\b(?:github|secrets)\b[\s\S]*\}\}/iu.test(text)) {
      reject(
        `workflow policy forbids credential expressions in ${repositoryPath(path)}`,
      );
    }
  });
}

function validatePermissionShape(value, path) {
  if (value === null || Array.isArray(value) || typeof value !== 'object') {
    reject(
      `workflow permissions must be an explicit read-only map in ${repositoryPath(path)}`,
    );
  }
  const allowed = { contents: 'read' };
  for (const [scope, access] of Object.entries(value)) {
    if (scope === 'contents' && access === 'read') continue;
    if (scope === 'security-events' && access === 'write') {
      allowed['security-events'] = 'write';
      continue;
    }
    reject(
      `workflow permission is not allowed in ${repositoryPath(path)}: ${scope}: ${access}`,
    );
  }
  if (value.contents !== 'read') {
    reject(
      `workflow permissions must retain contents: read in ${repositoryPath(path)}`,
    );
  }
  return allowed;
}

function localReferencePath(reference) {
  if (!reference.startsWith('./'))
    reject(`local reference must start with ./: ${reference}`);
  return resolve(root, reference);
}

function enterReference(path, state) {
  const absolutePath = resolve(path);
  if (state.active.has(absolutePath)) {
    reject(`local reference cycle detected: ${repositoryPath(absolutePath)}`);
  }
  state.count += 1;
  if (state.count > maxLocalReferences)
    reject(`local reference limit exceeded: ${maxLocalReferences}`);
  state.active.add(absolutePath);
  return true;
}

function leaveReference(path, state) {
  const absolutePath = resolve(path);
  state.active.delete(absolutePath);
}

function actionMetadata(reference) {
  const actionDirectory = localReferencePath(reference);
  assertNoSymlink(actionDirectory);
  for (const filename of ['action.yml', 'action.yaml']) {
    const path = join(actionDirectory, filename);
    if (existsSync(path)) return requireTrackedFile(path);
  }
  reject(
    `local action metadata is missing: ${repositoryPath(actionDirectory)}`,
  );
}

function classifyRemoteUse(
  reference,
  path,
  facts,
  step,
  { canonical = false } = {},
) {
  if (remoteReusablePattern.test(reference)) {
    reject(
      `remote reusable workflows are forbidden in ${repositoryPath(path)}`,
    );
  }
  if (!remoteActionPattern.test(reference)) {
    reject(
      `remote actions must use a full commit SHA in ${repositoryPath(path)}: ${reference}`,
    );
  }
  const action = reference.slice(0, reference.lastIndexOf('@'));
  const normalizedAction = action.toLowerCase();
  const disallowedStepKeys = Object.keys(step).filter(
    (key) => !['name', 'uses', 'with'].includes(key),
  );
  if (disallowedStepKeys.length > 0) {
    reject(
      `remote action steps must not define env or conditions in ${repositoryPath(path)}`,
    );
  }
  if (
    normalizedAction.startsWith('github/codeql-action/') &&
    normalizedAction !== 'github/codeql-action/upload-sarif'
  ) {
    reject(
      `advanced CodeQL actions are forbidden in ${repositoryPath(path)}: ${action}`,
    );
  }
  if (
    !allowedRemoteActions.has(normalizedAction) &&
    !(canonical && normalizedAction === 'actions/setup-node')
  ) {
    reject(
      `remote action is not allowed in ${repositoryPath(path)}: ${action}`,
    );
  }
  facts.actionUses += 1;
  if (
    normalizedAction === 'actions/checkout' &&
    (step.with === null ||
      typeof step.with !== 'object' ||
      step.with['persist-credentials'] !== false)
  ) {
    reject(
      `checkout must disable persisted credentials in ${repositoryPath(path)}`,
    );
  }
  if (
    normalizedAction === 'actions/checkout' &&
    (Object.keys(step.with).length !== 1 ||
      step.with['persist-credentials'] !== false)
  ) {
    reject(`checkout inputs are not allowed in ${repositoryPath(path)}`);
  }
  facts.remoteAction = true;
  if (normalizedAction.startsWith('github/codeql-action/')) {
    if (normalizedAction === 'github/codeql-action/upload-sarif') {
      facts.uploadSarif = true;
    }
  }
}

function scanSteps(
  steps,
  path,
  state,
  facts,
  { allowRemoteActions = true, canonical = false } = {},
) {
  if (steps === undefined) return;
  if (!Array.isArray(steps))
    reject(`workflow steps must be a sequence in ${repositoryPath(path)}`);
  for (const step of steps) {
    if (step === null || Array.isArray(step) || typeof step !== 'object') {
      reject(`workflow steps must be mappings in ${repositoryPath(path)}`);
    }
    if (typeof step.uses !== 'string') {
      if (step.run !== undefined) facts.priorExecutableStep = true;
      continue;
    }
    if (step.uses.startsWith('./')) {
      if (facts.priorExecutableStep) {
        reject(
          `local actions must not follow executable steps in ${repositoryPath(path)}`,
        );
      }
      const disallowedKeys = Object.keys(step).filter(
        (key) => !['name', 'uses', 'with'].includes(key),
      );
      if (disallowedKeys.length > 0) {
        reject(
          `local action steps must not define env or conditions in ${repositoryPath(path)}`,
        );
      }
      facts.actionUses += 1;
      facts.nonUploadAction = true;
      facts.priorExecutableStep = false;
      scanLocalAction(step.uses, state, facts);
      facts.priorExecutableStep = true;
    } else {
      if (!allowRemoteActions) {
        reject(
          `remote actions are forbidden inside local actions in ${repositoryPath(path)}`,
        );
      }
      if (facts.priorExecutableStep) {
        reject(
          `remote actions must not follow executable steps in ${repositoryPath(path)}`,
        );
      }
      const previousUploadSarif = facts.uploadSarif;
      classifyRemoteUse(step.uses, path, facts, step, { canonical });
      if (facts.uploadSarif === previousUploadSarif)
        facts.nonUploadAction = true;
    }
  }
}

function scanLocalAction(reference, state, facts) {
  const path = actionMetadata(reference);
  if (!enterReference(path, state)) return;
  const value = documentValue(parseYaml(path));
  rejectCredentialExpressions(value, path);
  if (
    value === null ||
    typeof value !== 'object' ||
    value.runs === null ||
    typeof value.runs !== 'object' ||
    value.runs.using !== 'composite'
  ) {
    reject(
      `local actions must use inspectable composite steps: ${repositoryPath(path)}`,
    );
  }
  scanSteps(value.runs.steps, path, state, facts, {
    allowRemoteActions: false,
  });
  leaveReference(path, state);
}

function scanWorkflow(path, state, { localReference = false } = {}) {
  const workflowPath = requireTrackedFile(path);
  if (localReference) enterReference(workflowPath, state);
  const value = documentValue(parseYaml(workflowPath));
  if (
    workflowPath === canonicalWorkflow &&
    !isDeepStrictEqual(value, canonicalContract)
  ) {
    reject('canonical Check workflow contract changed');
  }
  if (value === null || Array.isArray(value) || typeof value !== 'object') {
    reject(
      `workflow root must be a mapping in ${repositoryPath(workflowPath)}`,
    );
  }
  if (workflowPath !== canonicalWorkflow) {
    rejectCredentialExpressions(value, workflowPath);
  }
  if (value.env !== undefined || value.defaults !== undefined) {
    reject(
      `workflows must not define env or defaults in ${repositoryPath(workflowPath)}`,
    );
  }
  const permissions = validatePermissionShape(value.permissions, workflowPath);
  if (permissions['security-events'] === 'write') {
    reject(
      `workflow-level security-events: write is forbidden in ${repositoryPath(workflowPath)}`,
    );
  }
  const facts = { uploadSarif: false };
  if (
    value.jobs === null ||
    Array.isArray(value.jobs) ||
    typeof value.jobs !== 'object'
  ) {
    reject(
      `workflow jobs must be a mapping in ${repositoryPath(workflowPath)}`,
    );
  }
  for (const job of Object.values(value.jobs)) {
    if (job === null || Array.isArray(job) || typeof job !== 'object') {
      reject(
        `workflow jobs must contain mappings in ${repositoryPath(workflowPath)}`,
      );
    }
    if (
      job.env !== undefined ||
      job.defaults !== undefined ||
      job.if !== undefined
    ) {
      reject(
        `jobs must not define env, defaults, or conditions in ${repositoryPath(workflowPath)}`,
      );
    }
    const jobPermissions =
      job.permissions === undefined
        ? permissions
        : validatePermissionShape(job.permissions, workflowPath);
    const jobFacts = {
      actionUses: 0,
      delegatedSarif: false,
      nonUploadAction: false,
      priorExecutableStep: false,
      remoteAction: false,
      uploadSarif: false,
    };
    if (typeof job.uses === 'string') {
      if (job.steps !== undefined) {
        reject(
          `reusable workflow jobs must not define steps in ${repositoryPath(workflowPath)}`,
        );
      }
      if (!job.uses.startsWith('./')) {
        if (remoteReusablePattern.test(job.uses)) {
          reject(
            `remote reusable workflows are forbidden in ${repositoryPath(workflowPath)}`,
          );
        }
        reject(
          `invalid reusable workflow reference in ${repositoryPath(workflowPath)}: ${job.uses}`,
        );
      }
      const reusablePath = localReferencePath(job.uses);
      if (
        !/^\.github\/workflows\/[^/]+\.ya?ml$/u.test(
          repositoryPath(reusablePath),
        )
      ) {
        reject(
          `local reusable workflows must be direct .github/workflows files: ${job.uses}`,
        );
      }
      const reusableFacts = scanWorkflow(reusablePath, state, {
        localReference: true,
      });
      if (reusableFacts.uploadSarif) {
        const disallowedKeys = Object.keys(job).filter(
          (key) =>
            !['name', 'needs', 'permissions', 'uses', 'with'].includes(key),
        );
        if (disallowedKeys.length > 0) {
          reject(
            `privileged reusable upload-sarif jobs contain unsupported keys in ${repositoryPath(workflowPath)}`,
          );
        }
        jobFacts.delegatedSarif = true;
        jobFacts.uploadSarif = true;
      }
    }
    scanSteps(job.steps, workflowPath, state, jobFacts, {
      canonical: workflowPath === canonicalWorkflow,
    });
    if (workflowPath !== canonicalWorkflow && jobFacts.remoteAction) {
      const disallowedKeys = Object.keys(job).filter(
        (key) =>
          ![
            'name',
            'permissions',
            'runs-on',
            'steps',
            'timeout-minutes',
          ].includes(key),
      );
      if (disallowedKeys.length > 0) {
        reject(
          `remote-action jobs contain unsupported keys in ${repositoryPath(workflowPath)}`,
        );
      }
      if (job['runs-on'] !== 'ubuntu-24.04') {
        reject(
          `remote-action jobs must run on ubuntu-24.04 in ${repositoryPath(workflowPath)}`,
        );
      }
    }
    if (
      workflowPath !== canonicalWorkflow &&
      jobFacts.remoteAction &&
      job.steps.length !== 1
    ) {
      reject(
        `remote-action jobs must contain exactly one step in ${repositoryPath(workflowPath)}`,
      );
    }
    if (jobFacts.uploadSarif && jobPermissions['security-events'] !== 'write') {
      reject(
        `upload-sarif requires security-events: write in ${repositoryPath(workflowPath)}`,
      );
    }
    if (jobFacts.uploadSarif && !jobFacts.delegatedSarif) {
      const disallowedKeys = Object.keys(job).filter(
        (key) =>
          ![
            'name',
            'permissions',
            'runs-on',
            'steps',
            'timeout-minutes',
          ].includes(key),
      );
      if (disallowedKeys.length > 0) {
        reject(
          `privileged upload-sarif jobs must not define env, defaults, or conditions in ${repositoryPath(workflowPath)}`,
        );
      }
    }
    if (
      !jobFacts.uploadSarif &&
      jobPermissions['security-events'] === 'write'
    ) {
      reject(
        `security-events: write is allowed only for upload-sarif in ${repositoryPath(workflowPath)}`,
      );
    }
    if (
      jobFacts.uploadSarif &&
      !jobFacts.delegatedSarif &&
      (jobFacts.actionUses !== 1 || jobFacts.nonUploadAction)
    ) {
      reject(
        `upload-sarif must be the only action in its privileged job in ${repositoryPath(workflowPath)}`,
      );
    }
    if (
      jobFacts.uploadSarif &&
      !jobFacts.delegatedSarif &&
      job.steps.length !== 1
    ) {
      reject(
        `privileged upload-sarif jobs must contain exactly one step in ${repositoryPath(workflowPath)}`,
      );
    }
    facts.uploadSarif ||= jobFacts.uploadSarif;
  }
  if (
    facts.uploadSarif &&
    ((typeof value.on === 'string' && value.on === 'pull_request_target') ||
      (Array.isArray(value.on) && value.on.includes('pull_request_target')) ||
      (value.on !== null &&
        typeof value.on === 'object' &&
        Object.hasOwn(value.on, 'pull_request_target')))
  ) {
    reject(
      `upload-sarif is forbidden for pull_request_target in ${repositoryPath(workflowPath)}`,
    );
  }
  if (localReference) leaveReference(workflowPath, state);
  return facts;
}

function traversalState() {
  return { active: new Set(), count: 0 };
}

const files = workflowFiles(workflowsRoot);
if (!files.includes(canonicalWorkflow)) {
  reject('the canonical .github/workflows/check.yml workflow is required');
}
for (const path of files) scanWorkflow(path, traversalState());

console.log('workflow policy passed');
