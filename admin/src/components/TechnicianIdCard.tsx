import { useEffect, useRef, useState } from 'react';
import { api, errorMessage } from '../api/client';
import {
  uploadTechnicianIdCard,
  deleteTechnicianIdCard,
  uploadTechnicianFacePhoto,
  deleteTechnicianFacePhoto,
} from '../api/technicians';

export function TechnicianIdCard({
  id,
  identityEmailVerified,
  onUpdated,
}: {
  id: number;
  identityEmailVerified: boolean;
  onUpdated?: () => void;
}) {
  const [reloadKey, setReloadKey] = useState(0);

  const handleUpdated = () => {
    setReloadKey((k) => k + 1);
    onUpdated?.();
  };

  return (
    <div className="card pad">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
        <h2 style={{ margin: 0 }}>Identity verification</h2>
      </div>
      <p className="muted">
        Compare the ID card, registered name, and face photo before approving. Photos require manual review.
        You can replace, upload, or remove documents below.
      </p>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(min(280px, 100%), 1fr))',
          gap: 20,
          marginTop: 16,
        }}
      >
        <VerificationPhoto
          key={`id-card-${reloadKey}`}
          id={id}
          kind="id-card"
          title="ID card"
          onUpdated={handleUpdated}
        />
        {identityEmailVerified ? (
          <div>
            <h3>Face photo</h3>
            <div className="card pad" style={{ background: 'var(--surface-alt, #f4f6f8)', marginBottom: 12 }}>
              <p style={{ margin: 0 }}>
                <strong>✓ Verified via email</strong> instead of a face photo — this technician
                confirmed their identity by entering a one-time code sent to their registered
                email address.
              </p>
            </div>
            <VerificationPhoto
              key={`face-photo-${reloadKey}`}
              id={id}
              kind="face-photo"
              title="Add / Replace Face photo"
              onUpdated={handleUpdated}
            />
          </div>
        ) : (
          <VerificationPhoto
            key={`face-photo-${reloadKey}`}
            id={id}
            kind="face-photo"
            title="Face photo"
            onUpdated={handleUpdated}
          />
        )}
      </div>
    </div>
  );
}

function VerificationPhoto({
  id,
  kind,
  title,
  onUpdated,
}: {
  id: number;
  kind: 'id-card' | 'face-photo';
  title: string;
  onUpdated: () => void;
}) {
  const [url, setUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const loadPhoto = () => {
    let active = true;
    let objectUrl: string | undefined;
    setUrl(null);
    setError(null);
    setLoading(true);
    api
      .get<Blob>(`/api/admin/technicians/${id}/${kind}`, { responseType: 'blob' })
      .then(({ data }) => {
        if (!active) return;
        objectUrl = URL.createObjectURL(data);
        setUrl(objectUrl);
      })
      .catch((e) => {
        if (active) {
          setError(
            e.response?.status === 404
              ? `No ${title.toLowerCase()} submitted yet.`
              : errorMessage(e),
          );
        }
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  };

  useEffect(() => {
    return loadPhoto();
  }, [id, kind]);

  const handleFileSelected = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      setError('Please select a JPEG or PNG image file.');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setError('Image file must be 5 MB or smaller.');
      return;
    }

    setUploading(true);
    setError(null);
    setSuccess(null);
    try {
      if (kind === 'id-card') {
        await uploadTechnicianIdCard(id, file);
      } else {
        await uploadTechnicianFacePhoto(id, file);
      }
      setSuccess(`${title} updated successfully.`);
      loadPhoto();
      onUpdated();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const handleDelete = async () => {
    if (!window.confirm(`Are you sure you want to remove this ${title.toLowerCase()}?`)) {
      return;
    }
    setUploading(true);
    setError(null);
    setSuccess(null);
    try {
      if (kind === 'id-card') {
        await deleteTechnicianIdCard(id);
      } else {
        await deleteTechnicianFacePhoto(id);
      }
      setUrl(null);
      setSuccess(`${title} removed.`);
      onUpdated();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setUploading(false);
    }
  };

  return (
    <div style={{ border: '1px solid var(--border, #e2e8f0)', borderRadius: 8, padding: 16 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <h3 style={{ margin: 0 }}>{title}</h3>
        {url && (
          <span style={{ fontSize: 12, color: 'var(--success, #16a34a)', fontWeight: 600 }}>
            ✓ On file
          </span>
        )}
      </div>

      {loading && <p style={{ minHeight: 120 }}>Loading photo…</p>}
      {error && !loading && <p className="error-text" style={{ fontSize: 13 }}>{error}</p>}
      {success && <p style={{ color: 'var(--success, #16a34a)', fontSize: 13 }}>{success}</p>}

      {url && (
        <a href={url} target="_blank" rel="noreferrer" title="Click to view full image">
          <img
            src={url}
            alt={`Technician ${title.toLowerCase()}`}
            style={{
              width: '100%',
              height: 240,
              objectFit: 'contain',
              background: '#f8fafc',
              borderRadius: 6,
              marginBottom: 12,
            }}
          />
        </a>
      )}

      <div style={{ display: 'flex', gap: 8, marginTop: 10, flexWrap: 'wrap' }}>
        <input
          type="file"
          ref={fileInputRef}
          accept="image/jpeg,image/png"
          style={{ display: 'none' }}
          onChange={handleFileSelected}
        />
        <button
          type="button"
          className="btn"
          disabled={uploading}
          onClick={() => fileInputRef.current?.click()}
          style={{ fontSize: 13, padding: '6px 12px' }}
        >
          {uploading ? 'Uploading…' : url ? `Replace ${title}` : `Upload ${title}`}
        </button>
        {url && (
          <button
            type="button"
            className="btn danger"
            disabled={uploading}
            onClick={handleDelete}
            style={{ fontSize: 13, padding: '6px 12px' }}
          >
            Remove
          </button>
        )}
      </div>
    </div>
  );
}
