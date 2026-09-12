import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { getStats } from '../api/dashboard';
import { errorMessage } from '../api/client';

const CARDS: { key: keyof import('../api/types').DashboardStats; label: string; to: string }[] = [
  { key: 'pendingTechnicians', label: 'Pending approvals', to: '/technicians?approval=PENDING' },
  { key: 'activeTechnicians', label: 'Active technicians', to: '/technicians?approval=APPROVED&account=ACTIVE' },
  { key: 'suspendedTechnicians', label: 'Suspended', to: '/technicians?account=SUSPENDED' },
  { key: 'openJobs', label: 'Open jobs', to: '/jobs' },
  { key: 'unassignedJobs', label: 'Unassigned jobs', to: '/jobs?status=REQUESTED' },
  { key: 'completedJobs', label: 'Completed jobs', to: '/jobs?status=COMPLETED' },
];

export function DashboardPage() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['stats'],
    queryFn: getStats,
    refetchInterval: 30_000,
  });

  return (
    <>
      <div className="page-head">
        <h1>Dashboard</h1>
      </div>
      {error && <p className="error-text">{errorMessage(error)}</p>}
      {isLoading && <p className="muted">Loading…</p>}
      {data && (
        <div className="stat-grid">
          {CARDS.map((c) => (
            <Link key={c.key} to={c.to} className="card stat" style={{ color: 'inherit' }}>
              <div className="n">{data[c.key]}</div>
              <div className="l">{c.label}</div>
            </Link>
          ))}
        </div>
      )}
      <div className="card pad">
        <h2>Getting started</h2>
        <p className="muted">
          New technicians register from the CamFix app and land in{' '}
          <Link to="/technicians?approval=PENDING">Pending approvals</Link>. Approve them to
          make them dispatchable, then create jobs and assign them from{' '}
          <Link to="/jobs">Jobs</Link>. The <Link to="/map">Live map</Link> shows the last
          reported position of every active technician.
        </p>
      </div>
    </>
  );
}
