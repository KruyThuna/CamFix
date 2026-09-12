import { useState, type FormEvent } from 'react';
import { SERVICE_CATEGORIES, type Job, type JobInput } from '../api/types';

interface Props {
  initial?: Job;
  submitting: boolean;
  error?: string | null;
  onSubmit: (input: JobInput) => void;
  onCancel: () => void;
}

function toLocalInput(iso: string | null | undefined): string {
  if (!iso) return '';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '';
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(
    d.getHours(),
  )}:${pad(d.getMinutes())}`;
}

export function JobForm({ initial, submitting, error, onSubmit, onCancel }: Props) {
  const [f, setF] = useState({
    customerName: initial?.customerName ?? '',
    customerPhone: initial?.customerPhone ?? '',
    category: initial?.category ?? SERVICE_CATEGORIES[0],
    description: initial?.description ?? '',
    address: initial?.address ?? '',
    scheduledAt: toLocalInput(initial?.scheduledAt),
    notes: initial?.notes ?? '',
  });

  const set = (k: keyof typeof f, v: string) => setF((p) => ({ ...p, [k]: v }));

  const submit = (e: FormEvent) => {
    e.preventDefault();
    const payload: JobInput = {
      customerName: f.customerName,
      customerPhone: f.customerPhone,
      category: f.category,
      description: f.description,
      address: f.address || null,
      notes: f.notes || null,
      scheduledAt: f.scheduledAt ? new Date(f.scheduledAt).toISOString() : null,
    };
    onSubmit(payload);
  };

  return (
    <form onSubmit={submit}>
      <div className="form-grid">
        <div>
          <label>Customer name</label>
          <input
            required
            value={f.customerName}
            onChange={(e) => set('customerName', e.target.value)}
          />
        </div>
        <div>
          <label>Customer phone</label>
          <input
            required
            value={f.customerPhone}
            onChange={(e) => set('customerPhone', e.target.value)}
          />
        </div>
        <div>
          <label>Category</label>
          <select value={f.category} onChange={(e) => set('category', e.target.value)}>
            {SERVICE_CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label>Scheduled for (optional)</label>
          <input
            type="datetime-local"
            value={f.scheduledAt}
            onChange={(e) => set('scheduledAt', e.target.value)}
          />
        </div>
        <div className="full">
          <label>Address</label>
          <input value={f.address} onChange={(e) => set('address', e.target.value)} />
        </div>
        <div className="full">
          <label>Description</label>
          <textarea
            required
            rows={3}
            value={f.description}
            onChange={(e) => set('description', e.target.value)}
          />
        </div>
        <div className="full">
          <label>Internal notes</label>
          <textarea
            rows={2}
            value={f.notes}
            onChange={(e) => set('notes', e.target.value)}
          />
        </div>
      </div>
      {error && <p className="error-text" style={{ marginTop: 12 }}>{error}</p>}
      <div className="form-actions">
        <button type="submit" className="primary" disabled={submitting}>
          {submitting ? 'Saving…' : initial ? 'Save changes' : 'Create job'}
        </button>
        <button type="button" onClick={onCancel} disabled={submitting}>
          Cancel
        </button>
      </div>
    </form>
  );
}
