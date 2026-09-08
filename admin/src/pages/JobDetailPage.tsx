import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link, useParams } from 'react-router-dom';
import {
  assignJob,
  cancelJob,
  changeJobStatus,
  getJob,
  updateJob,
} from '../api/jobs';
import { listTechnicians } from '../api/technicians';
import { errorMessage } from '../api/client';
import type { JobStatus } from '../api/types';
import { JobStatusBadge } from '../components/StatusBadge';
import { JobForm } from '../components/JobForm';
import { fmtDate } from '../lib/format';

const NEXT: Record<JobStatus, JobStatus[]> = {
  REQUESTED: ['ASSIGNED', 'CANCELLED'],
  ASSIGNED: ['IN_PROGRESS', 'REQUESTED', 'CANCELLED'],
  IN_PROGRESS: ['COMPLETED', 'ASSIGNED', 'CANCELLED'],
  COMPLETED: [],
  CANCELLED: ['REQUESTED'],
};

export function JobDetailPage() {
  const { id } = useParams();
  const jobId = Number(id);
  const qc = useQueryClient();
  const [editing, setEditing] = useState(false);
  const [techChoice, setTechChoice] = useState<number | ''>('');
  const [actionError, setActionError] = useState<string | null>(null);

  const { data: j, isLoading, error } = useQuery({
    queryKey: ['job', jobId],
    queryFn: () => getJob(jobId),
    enabled: Number.isFinite(jobId),
  });

  const { data: techs } = useQuery({
    queryKey: ['technicians', { approval: 'APPROVED', account: 'ACTIVE' }],
    queryFn: () => listTechnicians({ approval: 'APPROVED', account: 'ACTIVE' }),
  });

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ['job', jobId] });
    qc.invalidateQueries({ queryKey: ['jobs'] });
    qc.invalidateQueries({ queryKey: ['stats'] });
  };

  const mut = useMutation({
    mutationFn: (fn: () => Promise<unknown>) => fn(),
    onSuccess: invalidate,
    onError: (e) => setActionError(errorMessage(e)),
  });

  const save = useMutation({
    mutationFn: (input: Parameters<typeof updateJob>[1]) => updateJob(jobId, input),
    onSuccess: () => {
      setEditing(false);
      invalidate();
    },
  });

  const run = (fn: () => Promise<unknown>) => {
    setActionError(null);
    mut.mutate(fn);
  };

  const techOptions = useMemo(
    () =>
      (techs ?? []).map((t) => ({
        id: t.id,
        label: `${t.firstName} ${t.lastName} — ${t.category}`,
      })),
    [techs],
  );

  if (isLoading) return <div className="empty">Loading…</div>;
  if (error) return <p className="error-text">{errorMessage(error)}</p>;
  if (!j) return null;

  return (
    <>
      <div className="page-head">
        <div>
          <Link to="/jobs" className="muted">
            ← Jobs
          </Link>
          <h1 style={{ marginTop: 4 }}>Job #{j.id}</h1>
        </div>
        <button onClick={() => setEditing((v) => !v)}>
          {editing ? 'Close editor' : 'Edit'}
        </button>
      </div>

      {actionError && <p className="error-text">{actionError}</p>}

      <div className="stack">
        <div className="card pad">
          <div className="inline" style={{ marginBottom: 14 }}>
            <JobStatusBadge status={j.status} />
            {j.technicianName ? (
              <span className="muted">
                Assigned to <strong>{j.technicianName}</strong> ({j.technicianPhone})
              </span>
            ) : (
              <span className="muted">Unassigned</span>
            )}
          </div>

          <div className="inline" style={{ marginBottom: 14 }}>
            <select
              value={techChoice}
              onChange={(e) =>
                setTechChoice(e.target.value ? Number(e.target.value) : '')
              }
              style={{ maxWidth: 320 }}
            >
              <option value="">Select technician…</option>
              {techOptions.map((o) => (
                <option key={o.id} value={o.id}>
                  {o.label}
                </option>
              ))}
            </select>
            <button
              className="primary"
              disabled={!techChoice || mut.isPending}
              onClick={() => run(() => assignJob(j.id, techChoice as number))}
            >
              {j.technicianId ? 'Reassign' : 'Assign'}
            </button>
          </div>

          <div className="inline">
            {NEXT[j.status].map((s) => (
              <button
                key={s}
                disabled={mut.isPending}
                className={s === 'CANCELLED' ? 'danger' : ''}
                onClick={() =>
                  run(() =>
                    s === 'CANCELLED'
                      ? cancelJob(j.id)
                      : changeJobStatus(j.id, s),
                  )
                }
              >
                → {s.replace('_', ' ')}
              </button>
            ))}
            {NEXT[j.status].length === 0 && (
              <span className="muted">No further status changes.</span>
            )}
          </div>
        </div>

        {editing ? (
          <div className="card pad">
            <h2 style={{ marginBottom: 14 }}>Edit job</h2>
            <JobForm
              initial={j}
              submitting={save.isPending}
              error={save.isError ? errorMessage(save.error) : null}
              onSubmit={(input) => save.mutate(input)}
              onCancel={() => setEditing(false)}
            />
          </div>
        ) : (
          <div className="card pad">
            <h2 style={{ marginBottom: 14 }}>Details</h2>
            <dl className="kv">
              <dt>Customer</dt>
              <dd>
                {j.customerName} · {j.customerPhone}
              </dd>
              <dt>Category</dt>
              <dd>{j.category}</dd>
              <dt>Description</dt>
              <dd>{j.description}</dd>
              <dt>Address</dt>
              <dd>{j.address ?? '—'}</dd>
              <dt>Notes</dt>
              <dd>{j.notes ?? '—'}</dd>
              <dt>Created</dt>
              <dd>{fmtDate(j.createdAt)}</dd>
              <dt>Scheduled</dt>
              <dd>{fmtDate(j.scheduledAt)}</dd>
              <dt>Assigned</dt>
              <dd>{fmtDate(j.assignedAt)}</dd>
              <dt>Completed</dt>
              <dd>{fmtDate(j.completedAt)}</dd>
            </dl>
          </div>
        )}
      </div>
    </>
  );
}
