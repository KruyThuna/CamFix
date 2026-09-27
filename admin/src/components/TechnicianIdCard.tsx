import { useEffect, useState } from 'react';
import { api, errorMessage } from '../api/client';

export function TechnicianIdCard({ id, identityEmailVerified }: { id: number; identityEmailVerified: boolean }) {
  return (
    <div className="card pad">
      <h2 style={{ marginBottom: 14 }}>Identity verification</h2>
      <p className="muted">Compare the ID card, registered name, and face photo before approving. Photos require manual review.</p>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(260px, 100%), 1fr))', gap: 20, marginTop: 16 }}>
        <VerificationPhoto id={id} kind="id-card" title="ID card" />
        {identityEmailVerified ? (
          <div>
            <h3>Face photo</h3>
            <div className="card pad" style={{ background: 'var(--surface-alt, #f4f6f8)' }}>
              <p style={{ margin: 0 }}>
                <strong>✓ Verified via email</strong> instead of a face photo — this technician
                confirmed their identity by entering a one-time code sent to their registered
                email address, so no face photo was submitted.
              </p>
            </div>
          </div>
        ) : (
          <VerificationPhoto id={id} kind="face-photo" title="Face photo" />
        )}
      </div>
    </div>
  );
}

function VerificationPhoto({ id, kind, title }: {
  id: number; kind: 'id-card' | 'face-photo'; title: string;
}) {
  const [url, setUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    let objectUrl: string | undefined;
    setUrl(null);
    setError(null);
    setLoading(true);
    api.get<Blob>(`/api/admin/technicians/${id}/${kind}`, { responseType: 'blob' })
      .then(({ data }) => {
        if (!active) return;
        objectUrl = URL.createObjectURL(data);
        setUrl(objectUrl);
      })
      .catch((e) => {
        if (active) setError(e.response?.status === 404
          ? `No ${title.toLowerCase()} submitted for this account.` : errorMessage(e));
      })
      .finally(() => { if (active) setLoading(false); });
    return () => {
      active = false;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [id, kind, title]);

  return (
    <div>
      <h3>{title}</h3>
      {loading && <p>Loading photo…</p>}
      {error && <p className="error-text">{error}</p>}
      {url && <a href={url} target="_blank" rel="noreferrer">
        <img src={url} alt={`Technician ${title.toLowerCase()}`} style={{ width: '100%', height: 320, objectFit: 'contain' }} />
      </a>}
    </div>
  );
}
