import type { AccountStatus, ApprovalStatus, JobStatus } from '../api/types';

type Tone = 'green' | 'amber' | 'red' | 'slate' | 'blue';

const APPROVAL: Record<ApprovalStatus, Tone> = {
  PENDING: 'amber',
  APPROVED: 'green',
  REJECTED: 'red',
};

const ACCOUNT: Record<AccountStatus, Tone> = {
  ACTIVE: 'green',
  SUSPENDED: 'red',
};

const JOB: Record<JobStatus, Tone> = {
  REQUESTED: 'amber',
  ASSIGNED: 'blue',
  IN_PROGRESS: 'blue',
  COMPLETED: 'green',
  CANCELLED: 'slate',
};

export function Badge({ tone, children }: { tone: Tone; children: React.ReactNode }) {
  return <span className={`badge ${tone}`}>{children}</span>;
}

export function ApprovalBadge({ status }: { status: ApprovalStatus }) {
  return <Badge tone={APPROVAL[status]}>{status}</Badge>;
}

export function AccountBadge({ status }: { status: AccountStatus }) {
  return <Badge tone={ACCOUNT[status]}>{status}</Badge>;
}

export function JobStatusBadge({ status }: { status: JobStatus }) {
  return <Badge tone={JOB[status]}>{status.replace('_', ' ')}</Badge>;
}
