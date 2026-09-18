import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useSearchParams } from 'react-router-dom';
import { listUsers, resetUserPassword, type UserFilters } from '../api/users';
import { errorMessage } from '../api/client';
import type { PasswordResetResult, UserInfo } from '../api/types';
import { Badge } from '../components/StatusBadge';
import { Modal } from '../components/Modal';

const ROLE_TONE: Record<string, 'green' | 'amber' | 'red' | 'slate' | 'blue'> = {
  ADMIN: 'red',
  TECHNICIAN: 'blue',
  CUSTOMER: 'slate',
};

export function UsersPage() {
  const [params, setParams] = useSearchParams();
  const qc = useQueryClient();
  const [actionError, setActionError] = useState<string | null>(null);
  const [reset, setReset] = useState<PasswordResetResult | null>(null);

  const filters: UserFilters = useMemo(
    () => ({
      role: params.get('role') ?? '',
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
    queryKey: ['users', filters],
    queryFn: () => listUsers(filters),
  });

  const reseter = useMutation({
    mutationFn: resetUserPassword,
    onSuccess: (result) => {
      setActionError(null);
      setReset(result);
      qc.invalidateQueries({ queryKey: ['users'] });
    },
    onError: (e) => setActionError(errorMessage(e)),
  });

  return (
    <>
      <div className="page-head">
        <h1>Users</h1>
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
          <label>Role</label>
          <select value={filters.role} onChange={(e) => setFilter('role', e.target.value)}>
            <option value="">All</option>
            <option value="ADMIN">Admin</option>
            <option value="TECHNICIAN">Technician</option>
            <option value="CUSTOMER">Customer</option>
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
              <th>Phone</th>
              <th>Role</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {data?.map((u) => (
              <Row key={u.id} u={u} busy={reseter.isPending} onReset={() => reseter.mutate(u.id)} />
            ))}
          </tbody>
        </table>
        {isLoading && <div className="empty">Loading…</div>}
        {data && data.length === 0 && <div className="empty">No users match.</div>}
      </div>

      {reset && (
        <Modal title="Password reset" onClose={() => setReset(null)}>
          <p>
            New temporary password for <strong>{reset.email}</strong>:
          </p>
          <p>
            <code style={{ fontSize: 16 }}>{reset.temporaryPassword}</code>
          </p>
          <p className="sub">
            This is shown once. Share it with the user through a secure channel — it
            can't be retrieved again after you close this dialog.
          </p>
        </Modal>
      )}
    </>
  );
}

function Row({
  u,
  busy,
  onReset,
}: {
  u: UserInfo;
  busy: boolean;
  onReset: () => void;
}) {
  return (
    <tr>
      <td>
        {u.firstName} {u.lastName}
        <div className="muted" style={{ fontSize: 12 }}>
          {u.email}
        </div>
      </td>
      <td>{u.phoneNumber}</td>
      <td><Badge tone={ROLE_TONE[u.role?.toUpperCase()] ?? 'slate'}>{u.role}</Badge></td>
      <td><Badge tone={u.status === 'SUSPENDED' ? 'red' : 'green'}>{u.status}</Badge></td>
      <td className="actions">
        <button
          className="small"
          disabled={busy}
          onClick={() => {
            if (window.confirm(`Reset the password for ${u.email}?`)) onReset();
          }}
        >
          Reset password
        </button>
      </td>
    </tr>
  );
}
