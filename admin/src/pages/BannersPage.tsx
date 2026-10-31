import { useState, type FormEvent, type ChangeEvent } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  listBanners,
  createBanner,
  updateBanner,
  deleteBanner,
  type AppBanner,
} from '../api/banners';
import { errorMessage } from '../api/client';
import { SERVICE_CATEGORIES } from '../api/types';

interface BannerFormState {
  title: string;
  subtitle: string;
  category: string;
  actionUrl: string;
  displayOrder: number;
  active: boolean;
  file: File | null;
}

const defaultForm: BannerFormState = {
  title: '',
  subtitle: '',
  category: '',
  actionUrl: '',
  displayOrder: 0,
  active: true,
  file: null,
};

export function BannersPage() {
  const qc = useQueryClient();
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<AppBanner | null>(null);
  const [form, setForm] = useState<BannerFormState>(defaultForm);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const query = useQuery({
    queryKey: ['admin-banners'],
    queryFn: listBanners,
  });

  const saveMutation = useMutation({
    mutationFn: async () => {
      const data = new FormData();
      data.append('title', form.title.trim());
      if (form.subtitle.trim()) data.append('subtitle', form.subtitle.trim());
      if (form.category.trim()) data.append('category', form.category.trim());
      if (form.actionUrl.trim()) data.append('actionUrl', form.actionUrl.trim());
      data.append('displayOrder', String(form.displayOrder));
      data.append('active', String(form.active));
      if (form.file) {
        data.append('file', form.file);
      }

      if (editing) {
        return updateBanner(editing.id, data);
      }
      return createBanner(data);
    },
    onSuccess: () => {
      setCreating(false);
      setEditing(null);
      setForm(defaultForm);
      setPreviewUrl(null);
      setError(null);
      setSuccess('Banner saved successfully!');
      qc.invalidateQueries({ queryKey: ['admin-banners'] });
      setTimeout(() => setSuccess(null), 3000);
    },
    onError: (e) => setError(errorMessage(e)),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => deleteBanner(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-banners'] });
      setSuccess('Banner deleted successfully!');
      setTimeout(() => setSuccess(null), 3000);
    },
    onError: (e) => setError(errorMessage(e)),
  });

  const toggleActiveMutation = useMutation({
    mutationFn: async (b: AppBanner) => {
      const data = new FormData();
      data.append('title', b.title);
      data.append('active', String(!b.active));
      return updateBanner(b.id, data);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-banners'] });
    },
    onError: (e) => setError(errorMessage(e)),
  });

  const handleFileChange = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setForm({ ...form, file });
      setPreviewUrl(URL.createObjectURL(file));
    }
  };

  const startEdit = (b: AppBanner) => {
    setEditing(b);
    setCreating(false);
    setForm({
      title: b.title,
      subtitle: b.subtitle ?? '',
      category: b.category ?? '',
      actionUrl: b.actionUrl ?? '',
      displayOrder: b.displayOrder,
      active: b.active,
      file: null,
    });
    setPreviewUrl(b.imageUrl ? `${b.imageUrl}` : null);
    setError(null);
  };

  const startCreate = () => {
    setCreating(true);
    setEditing(null);
    setForm(defaultForm);
    setPreviewUrl(null);
    setError(null);
  };

  const cancelForm = () => {
    setCreating(false);
    setEditing(null);
    setForm(defaultForm);
    setPreviewUrl(null);
    setError(null);
  };

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()) {
      setError('Title is required');
      return;
    }
    setError(null);
    saveMutation.mutate();
  };

  const banners = query.data ?? [];

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Client App Banners</h1>
          <p className="sub">
            Manage promotional hero banners shown on the Client App Home/Dashboard carousel.
          </p>
        </div>
        {!creating && !editing && (
          <button className="primary" onClick={startCreate}>
            + Upload New Banner
          </button>
        )}
      </div>

      {error && (
        <div style={{ padding: '12px 16px', background: '#fee2e2', color: '#b91c1c', borderRadius: 8, marginBottom: 16 }}>
          {error}
        </div>
      )}

      {success && (
        <div style={{ padding: '12px 16px', background: '#dcfce7', color: '#15803d', borderRadius: 8, marginBottom: 16 }}>
          {success}
        </div>
      )}

      {(creating || editing) && (
        <form className="card pad stack" onSubmit={handleSubmit} style={{ marginBottom: 24 }}>
          <h2>{editing ? 'Edit Banner' : 'Upload New Promotional Banner'}</h2>
          <p className="muted" style={{ margin: 0 }}>
            Upload an eye-catching banner image (16:9 or 3:1 aspect ratio recommended, max 10MB).
          </p>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 16 }}>
            <div>
              <label htmlFor="banner-title" style={{ display: 'block', fontWeight: 600, marginBottom: 4 }}>
                Banner Title *
              </label>
              <input
                id="banner-title"
                required
                maxLength={150}
                placeholder="e.g. 20% Off Air Conditioner Cleaning"
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
                style={{ width: '100%', padding: '8px 12px', borderRadius: 6, border: '1px solid #cbd5e1' }}
              />
            </div>

            <div>
              <label htmlFor="banner-subtitle" style={{ display: 'block', fontWeight: 600, marginBottom: 4 }}>
                Subtitle / Description
              </label>
              <input
                id="banner-subtitle"
                maxLength={255}
                placeholder="e.g. Fast service by certified technicians"
                value={form.subtitle}
                onChange={(e) => setForm({ ...form, subtitle: e.target.value })}
                style={{ width: '100%', padding: '8px 12px', borderRadius: 6, border: '1px solid #cbd5e1' }}
              />
            </div>

            <div>
              <label htmlFor="banner-category" style={{ display: 'block', fontWeight: 600, marginBottom: 4 }}>
                Target Service Category
              </label>
              <select
                id="banner-category"
                value={form.category}
                onChange={(e) => setForm({ ...form, category: e.target.value })}
                style={{ width: '100%', padding: '8px 12px', borderRadius: 6, border: '1px solid #cbd5e1' }}
              >
                <option value="">General / None (Opens Services screen)</option>
                {SERVICE_CATEGORIES.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label htmlFor="banner-order" style={{ display: 'block', fontWeight: 600, marginBottom: 4 }}>
                Display Order
              </label>
              <input
                id="banner-order"
                type="number"
                min={0}
                placeholder="0"
                value={form.displayOrder}
                onChange={(e) => setForm({ ...form, displayOrder: Number(e.target.value) || 0 })}
                style={{ width: '100%', padding: '8px 12px', borderRadius: 6, border: '1px solid #cbd5e1' }}
              />
            </div>
          </div>

          <div>
            <label htmlFor="banner-file" style={{ display: 'block', fontWeight: 600, marginBottom: 4 }}>
              Banner Image File {editing ? '(Leave blank to keep existing image)' : '*'}
            </label>
            <input
              id="banner-file"
              type="file"
              accept="image/*"
              onChange={handleFileChange}
              style={{ display: 'block', marginTop: 4 }}
            />
          </div>

          {previewUrl && (
            <div style={{ marginTop: 12 }}>
              <span style={{ fontSize: 13, color: '#64748b', display: 'block', marginBottom: 6 }}>
                Image Preview:
              </span>
              <img
                src={previewUrl}
                alt="Banner preview"
                style={{
                  maxHeight: 180,
                  maxWidth: '100%',
                  borderRadius: 12,
                  objectFit: 'cover',
                  border: '1px solid #e2e8f0',
                }}
              />
            </div>
          )}

          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
            <input
              id="banner-active"
              type="checkbox"
              checked={form.active}
              onChange={(e) => setForm({ ...form, active: e.target.checked })}
              style={{ width: 18, height: 18 }}
            />
            <label htmlFor="banner-active" style={{ fontWeight: 600, cursor: 'pointer' }}>
              Active (Visible immediately in Client App carousel)
            </label>
          </div>

          <div style={{ display: 'flex', gap: 12, marginTop: 16 }}>
            <button className="primary" type="submit" disabled={saveMutation.isPending}>
              {saveMutation.isPending ? 'Saving...' : editing ? 'Update Banner' : 'Create Banner'}
            </button>
            <button type="button" onClick={cancelForm}>
              Cancel
            </button>
          </div>
        </form>
      )}

      {query.isLoading ? (
        <p>Loading banners...</p>
      ) : banners.length === 0 ? (
        <div className="card pad" style={{ textAlign: 'center', padding: '48px 24px' }}>
          <p style={{ fontSize: 16, color: '#64748b', marginBottom: 16 }}>
            No custom app banners created yet. The Client App is currently displaying default system banners.
          </p>
          <button className="primary" onClick={startCreate}>
            + Upload Your First Banner
          </button>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 18 }}>
          {banners.map((b) => (
            <div
              key={b.id}
              className="card"
              style={{
                borderRadius: 14,
                overflow: 'hidden',
                display: 'flex',
                flexDirection: 'column',
                border: b.active ? '1px solid #cbd5e1' : '1px dashed #94a3b8',
                opacity: b.active ? 1 : 0.75,
              }}
            >
              <div
                style={{
                  height: 140,
                  background: '#0f172a',
                  position: 'relative',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {b.imageUrl ? (
                  <img
                    src={b.imageUrl}
                    alt={b.title}
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                ) : (
                  <span style={{ color: '#94a3b8', fontSize: 14 }}>No Image</span>
                )}
                <div
                  style={{
                    position: 'absolute',
                    top: 10,
                    right: 10,
                    background: b.active ? '#10b981' : '#64748b',
                    color: '#fff',
                    padding: '2px 8px',
                    borderRadius: 12,
                    fontSize: 11,
                    fontWeight: 700,
                  }}
                >
                  {b.active ? 'ACTIVE' : 'INACTIVE'}
                </div>
              </div>

              <div style={{ padding: 16, display: 'flex', flexDirection: 'column', flex: 1 }}>
                <h3 style={{ margin: '0 0 4px', fontSize: 16, fontWeight: 700 }}>{b.title}</h3>
                {b.subtitle && (
                  <p style={{ margin: '0 0 8px', fontSize: 13, color: '#64748b' }}>{b.subtitle}</p>
                )}
                <div style={{ fontSize: 12, color: '#475569', marginBottom: 12, display: 'flex', gap: 12, flexWrap: 'wrap' }}>
                  <span>📂 <strong>{b.category || 'General'}</strong></span>
                  <span>🔢 Order: <strong>{b.displayOrder}</strong></span>
                </div>

                <div style={{ marginTop: 'auto', display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  <button
                    style={{ fontSize: 12, padding: '4px 10px' }}
                    onClick={() => toggleActiveMutation.mutate(b)}
                  >
                    {b.active ? 'Disable' : 'Enable'}
                  </button>
                  <button
                    style={{ fontSize: 12, padding: '4px 10px' }}
                    onClick={() => startEdit(b)}
                  >
                    Edit
                  </button>
                  <button
                    style={{ fontSize: 12, padding: '4px 10px', color: '#dc2626' }}
                    onClick={() => {
                      if (window.confirm(`Are you sure you want to delete banner "${b.title}"?`)) {
                        deleteMutation.mutate(b.id);
                      }
                    }}
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
