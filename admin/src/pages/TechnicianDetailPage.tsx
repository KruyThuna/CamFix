import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { useState } from 'react';
import {
  approveTechnician,
  deleteTechnician,
  getTechnician,
  reactivateTechnician,
  rejectTechnician,
  suspendTechnician,
  updateTechnician,
} from '../api/technicians';
import { errorMessage } from '../api/client';
import { AccountBadge, ApprovalBadge, Badge } from '../components/StatusBadge';
import { TechnicianForm } from '../components/TechnicianForm';
import { fmtDate, fmtRelative } from '../lib/format';

export function TechnicianDetailPage() {
  const { id } = useParams();
  const techId = Number(id);
  const qc = useQueryClient();
  const navigate = useNavigate();
  const [editing, setEditing] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const { data: t, isLoading, error } = useQuery({
    queryKey: ['technician', techId],
    queryFn: () => getTechnician(techId),
    enabled: Number.isFinite(techId),
  });

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ['technician', techId] });
    qc.invalidateQueries({ queryKey: ['technicians'] });
    qc.invalidateQueries({ queryKey: ['stats'] });
  };

  const save = useMutation({
    mutationFn: (input: Parameters<typeof updateTechnician>[1]) =>
      updateTechnician(techId, input),
    onSuccess: () => {
      setEditing(false);
      invalidate();
    },
  });

  const runAction = useMutation({
    mutationFn: (fn: () => Promise<unknown>) => fn(),
    onSuccess: invalidate,
    onError: (e) => setActionError(errorMessage(e)),
  });

  const remove = useMutation({
    mutationFn: () => deleteTechnician(techId),
    onSuccess: () => {
      invalidate();
      navigate('/technicians', { replace: true });
    },
    onError: (e) => setActionError(errorMessage(e)),
  });

  const act = (fn: () => Promise<unknown>) => {
    setActionError(null);
    runAction.mutate(fn);
  };

  if (isLoading) return <div className="empty">Loading…</div>;
  if (error) return <p className="error-text">{errorMessage(error)}</p>;
  if (!t) return null;

  return (
    <>
      <div className="page-head">
        <div>
          <Link to="/technicians" className="muted">
            ← Technicians
          </Link>
          <h1 style={{ marginTop: 4 }}>
            {t.firstName} {t.lastName}
          </h1>
        </div>
        <div className="inline">
          <button onClick={() => setEditing((v) => !v)}>
            {editing ? 'Close editor' : 'Edit'}
          </button>
          <button
            className="danger"
            disabled={remove.isPending}
            onClick={() => {
              if (window.confirm('Delete this technician permanently?')) remove.mutate();
            }}
          >
            Delete
          </button>
        </div>
      </div>

      {actionError && <p className="error-text">{actionError}</p>}

      <div className="stack">
        <div className="card pad">
          <div className="inline" style={{ marginBottom: 14 }}>
            <ApprovalBadge status={t.approvalStatus} />
            <AccountBadge status={t.accountStatus} />
            <Badge tone={t.available ? 'green' : 'slate'}>
              {t.available ? 'Available' : 'Unavailable'}
            </Badge>
          </div>
          <div className="inline">
            {t.approvalStatus !== 'APPROVED' && (
              <button
                className="primary"
                disabled={runAction.isPending}
                onClick={() => act(() => approveTechnician(t.id))}
              >
                Approve
              </button>
            )}
            {t.approvalStatus !== 'REJECTED' && (
              <button
                className="danger"
                disabled={runAction.isPending}
                onClick={() => {
                  const reason = window.prompt('Rejection reason (optional):') ?? '';
                  act(() => rejectTechnician(t.id, reason));
                }}
              >
                Reject
              </button>
            )}
            {t.accountStatus === 'ACTIVE' ? (
              <button
                className="danger"
                disabled={runAction.isPending}
                onClick={() => act(() => suspendTechnician(t.id))}
              >
                Suspend
              </button>
            ) : (
              <button
                disabled={runAction.isPending}
                onClick={() => act(() => reactivateTechnician(t.id))}
              >
                Reactivate
              </button>
            )}
          </div>
          {t.rejectionReason && (
            <p className="muted" style={{ marginTop: 12 }}>
              Rejection reason: {t.rejectionReason}
            </p>
          )}
        </div>

        {editing ? (
          <div className="card pad">
            <h2 style={{ marginBottom: 14 }}>Edit profile</h2>
            <TechnicianForm
              initial={t}
              submitting={save.isPending}
              error={save.isError ? errorMessage(save.error) : null}
              onSubmit={(input) => save.mutate(input)}
              onCancel={() => setEditing(false)}
            />
          </div>
        ) : (
          <div className="card pad">
            <h2 style={{ marginBottom: 14 }}>Profile</h2>
            <dl className="kv">
              <dt>Email</dt>
              <dd>{t.email}</dd>
              <dt>Phone</dt>
              <dd>{t.phoneNumber}</dd>
              <dt>Category</dt>
              <dd>{t.category}</dd>
              <dt>Service area</dt>
              <dd>{t.serviceArea}</dd>
              <dt>Rating</dt>
              <dd>
                {t.rating.toFixed(1)} ({t.ratingCount})
              </dd>
              <dt>Opening hours</dt>
              <dd>{t.openingHours ?? '—'}</dd>
              <dt>About</dt>
              <dd>{t.about ?? '—'}</dd>
              <dt>Registered</dt>
              <dd>{fmtDate(t.createdAt)}</dd>
              <dt>Approved</dt>
              <dd>{fmtDate(t.approvedAt)}</dd>
            </dl>
          </div>
        )}

        <div className="card pad">
          <h2 style={{ marginBottom: 14 }}>Last known location</h2>
          {t.lastLat != null && t.lastLng != null ? (
            <p>
              {t.lastLat.toFixed(5)}, {t.lastLng.toFixed(5)}{' '}
              <span className="muted">· reported {fmtRelative(t.lastLocationAt)}</span>{' '}
              <a
                href={`https://www.openstreetmap.org/?mlat=${t.lastLat}&mlon=${t.lastLng}#map=15/${t.lastLat}/${t.lastLng}`}
                target="_blank"
                rel="noreferrer"
              >
                View on map
              </a>
            </p>
          ) : (
            <p className="muted">No location reported yet.</p>
          )}
        </div>
      </div>
    </>
  );
}
