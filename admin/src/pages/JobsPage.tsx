import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link, useSearchParams } from 'react-router-dom';
import { createJob, listJobs, type JobFilters } from '../api/jobs';
import { errorMessage } from '../api/client';
import type { Job, JobStatus } from '../api/types';
import { JobStatusBadge } from '../components/StatusBadge';
import { Modal } from '../components/Modal';
import { JobForm } from '../components/JobForm';
import { fmtDate } from '../lib/format';

const STATUSES: JobStatus[] = [
  'REQUESTED',
  'ASSIGNED',
  'IN_PROGRESS',
  'COMPLETED',
  'CANCELLED',
];

export function JobsPage() {
  const [params, setParams] = useSearchParams();
  const qc = useQueryClient();
  const [creating, setCreating] = useState(false);

  const filters: JobFilters = useMemo(
    () => ({
      status: (params.get('status') as JobStatus) ?? '',
      q: params.get('q') ?? '',
    }),
    [params],
  );

  const setFilter = (key: string, value: string) => {
    const next = new URLSearchParams(params);
    if (value) next.set(key, value);
    else next.delete(key);
    setParams(next, { replace: true });
  };

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['jobs', filters],
    queryFn: () => listJobs(filters),
  });

  const create = useMutation({
    mutationFn: createJob,
    onSuccess: () => {
      setCreating(false);
      qc.invalidateQueries({ queryKey: ['jobs'] });
      qc.invalidateQueries({ queryKey: ['stats'] });
    },
  });

  return (
    <>
      <div className="page-head">
        <h1>Jobs</h1>
        <button className="primary" onClick={() => setCreating(true)}>
          + New job
        </button>
      </div>

      <div className="toolbar">
        <div className="field grow">
          <label>Search</label>
          <input
            placeholder="Customer, phone or category"
            defaultValue={filters.q}
            onChange={(e) => setFilter('q', e.target.value)}
          />
        </div>
        <div className="field">
          <label>Status</label>
          <select
            value={filters.status}
            onChange={(e) => setFilter('status', e.target.value)}
          >
            <option value="">All</option>
            {STATUSES.map((s) => (
              <option key={s} value={s}>
                {s.replace('_', ' ')}
              </option>
            ))}
          </select>
        </div>
      </div>

      {error && (
        <p className="error-text">
          {errorMessage(error)}{' '}
          <button className="small" onClick={() => refetch()}>
            Retry
          </button>
        </p>
      )}

      <div className="card table-wrap">
        <table>
          <thead>
            <tr>
              <th>#</th>
              <th>Customer</th>
              <th>Category</th>
              <th>Status</th>
              <th>Technician</th>
              <th>Created</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {data?.map((j: Job) => (
              <tr key={j.id}>
                <td>
                  <Link to={`/jobs/${j.id}`}>{j.id}</Link>
                </td>
                <td>
                  {j.customerName}
                  <div className="muted" style={{ fontSize: 12 }}>
                    {j.customerPhone}
                  </div>
                </td>
                <td>{j.category}</td>
                <td>
                  <JobStatusBadge status={j.status} />
                </td>
                <td>{j.technicianName ?? <span className="muted">Unassigned</span>}</td>
                <td>{fmtDate(j.createdAt)}</td>
                <td>
                  <Link to={`/jobs/${j.id}`}>Open</Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {isLoading && <div className="empty">Loading…</div>}
        {data && data.length === 0 && <div className="empty">No jobs match.</div>}
      </div>

      {creating && (
        <Modal title="New job" onClose={() => setCreating(false)}>
          <JobForm
            submitting={create.isPending}
            error={create.isError ? errorMessage(create.error) : null}
            onSubmit={(input) => create.mutate(input)}
            onCancel={() => setCreating(false)}
          />
        </Modal>
      )}
    </>
  );
}
