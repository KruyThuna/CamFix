import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link, useSearchParams } from 'react-router-dom';
import {
  approveTechnician,
  createTechnician,
  listTechnicians,
  reactivateTechnician,
  rejectTechnician,
  suspendTechnician,
  type TechnicianFilters,
} from '../api/technicians';
import { errorMessage } from '../api/client';
import { SERVICE_CATEGORIES, type Technician } from '../api/types';
import { AccountBadge, ApprovalBadge } from '../components/StatusBadge';
import { Modal } from '../components/Modal';
import { TechnicianForm } from '../components/TechnicianForm';
import { fmtDate } from '../lib/format';

export function TechniciansPage() {
  const [params, setParams] = useSearchParams();
  const qc = useQueryClient();
  const [creating, setCreating] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const filters: TechnicianFilters = useMemo(
    () => ({
      approval: (params.get('approval') as TechnicianFilters['approval']) ?? '',
      account: (params.get('account') as TechnicianFilters['account']) ?? '',
      category: params.get('category') ?? '',
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
    queryKey: ['technicians', filters],
    queryFn: () => listTechnicians(filters),
  });

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ['technicians'] });
    qc.invalidateQueries({ queryKey: ['stats'] });
  };

  const runAction = useMutation({
    mutationFn: (fn: () => Promise<unknown>) => fn(),
    onSuccess: invalidate,
    onError: (e) => setActionError(errorMessage(e)),
  });

  const create = useMutation({
    mutationFn: createTechnician,
    onSuccess: () => {
      setCreating(false);
      invalidate();
    },
  });

  const act = (fn: () => Promise<unknown>) => {
    setActionError(null);
    runAction.mutate(fn);
  };

  return (
    <>
      <div className="page-head">
        <h1>Technicians</h1>
        <button className="primary" onClick={() => setCreating(true)}>
          + New technician
        </button>
      </div>

      <div className="toolbar">
        <div className="field grow">
          <label>Search</label>
          <input
            placeholder="Name, email or phone"
            defaultValue={filters.q}
            onChange={(e) => setFilter('q', e.target.value)}
          />
        </div>
        <div className="field">
          <label>Approval</label>
          <select
            value={filters.approval}
            onChange={(e) => setFilter('approval', e.target.value)}
          >
            <option value="">All</option>
            <option value="PENDING">Pending</option>
            <option value="APPROVED">Approved</option>
            <option value="REJECTED">Rejected</option>
          </select>
        </div>
        <div className="field">
          <label>Account</label>
          <select
            value={filters.account}
            onChange={(e) => setFilter('account', e.target.value)}
          >
            <option value="">All</option>
            <option value="ACTIVE">Active</option>
            <option value="SUSPENDED">Suspended</option>
          </select>
        </div>
        <div className="field">
          <label>Category</label>
          <select
            value={filters.category}
            onChange={(e) => setFilter('category', e.target.value)}
          >
            <option value="">All</option>
            {SERVICE_CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>
      </div>

      {actionError && <p className="error-text">{actionError}</p>}
      {error && (
        <p className="error-text">
          {errorMessage(error)} <button className="small" onClick={() => refetch()}>Retry</button>
        </p>
      )}

      <div className="card table-wrap">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Category</th>
              <th>Area</th>
              <th>Approval</th>
              <th>Account</th>
              <th>Registered</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {data?.map((t) => (
              <Row key={t.id} t={t} busy={runAction.isPending} onAction={act} />
            ))}
          </tbody>
        </table>
        {isLoading && <div className="empty">Loading…</div>}
        {data && data.length === 0 && <div className="empty">No technicians match.</div>}
      </div>

      {creating && (
        <Modal title="New technician" onClose={() => setCreating(false)}>
          <TechnicianForm
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

function Row({
  t,
  busy,
  onAction,
}: {
  t: Technician;
  busy: boolean;
  onAction: (fn: () => Promise<unknown>) => void;
}) {
  return (
    <tr>
      <td>
        <Link to={`/technicians/${t.id}`}>
          {t.firstName} {t.lastName}
        </Link>
        <div className="muted" style={{ fontSize: 12 }}>
          {t.email}
        </div>
      </td>
      <td>{t.category}</td>
      <td>{t.serviceArea}</td>
      <td><ApprovalBadge status={t.approvalStatus} /></td>
      <td><AccountBadge status={t.accountStatus} /></td>
      <td>{fmtDate(t.createdAt)}</td>
      <td className="actions">
        {t.approvalStatus === 'PENDING' && (
          <>
            <button
              className="small primary"
              disabled={busy}
              onClick={() => onAction(() => approveTechnician(t.id))}
            >
              Approve
            </button>
            <button
              className="small danger"
              disabled={busy}
              onClick={() => {
                const reason = window.prompt('Rejection reason (optional):') ?? '';
                onAction(() => rejectTechnician(t.id, reason));
              }}
            >
              Reject
            </button>
          </>
        )}
        {t.approvalStatus === 'APPROVED' && t.accountStatus === 'ACTIVE' && (
          <button
            className="small danger"
            disabled={busy}
            onClick={() => onAction(() => suspendTechnician(t.id))}
          >
            Suspend
          </button>
        )}
        {t.accountStatus === 'SUSPENDED' && (
          <button
            className="small"
            disabled={busy}
            onClick={() => onAction(() => reactivateTechnician(t.id))}
          >
            Reactivate
          </button>
        )}
        <Link className="small" to={`/technicians/${t.id}`} style={{ padding: '4px 9px' }}>
          Open
        </Link>
      </td>
    </tr>
  );
}
