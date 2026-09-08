import { useState, type FormEvent } from 'react';
import { SERVICE_CATEGORIES, type Technician, type TechnicianInput } from '../api/types';

interface Props {
  initial?: Technician;
  submitting: boolean;
  error?: string | null;
  onSubmit: (input: TechnicianInput) => void;
  onCancel: () => void;
}

export function TechnicianForm({ initial, submitting, error, onSubmit, onCancel }: Props) {
  const [f, setF] = useState<TechnicianInput>({
    firstName: initial?.firstName ?? '',
    lastName: initial?.lastName ?? '',
    email: initial?.email ?? '',
    phoneNumber: initial?.phoneNumber ?? '',
    category: initial?.category ?? SERVICE_CATEGORIES[0],
    serviceArea: initial?.serviceArea ?? '',
    about: initial?.about ?? '',
    openingHours: initial?.openingHours ?? '',
    rating: initial?.rating ?? 0,
    available: initial?.available ?? true,
  });

  const set = <K extends keyof TechnicianInput>(k: K, v: TechnicianInput[K]) =>
    setF((p) => ({ ...p, [k]: v }));

  const submit = (e: FormEvent) => {
    e.preventDefault();
    onSubmit({ ...f, rating: Number(f.rating) || 0 });
  };

  return (
    <form onSubmit={submit}>
      <div className="form-grid">
        <div>
          <label>First name</label>
          <input
            required
            value={f.firstName}
            onChange={(e) => set('firstName', e.target.value)}
          />
        </div>
        <div>
          <label>Last name</label>
          <input
            required
            value={f.lastName}
            onChange={(e) => set('lastName', e.target.value)}
          />
        </div>
        <div>
          <label>Email</label>
          <input
            type="email"
            required
            value={f.email}
            onChange={(e) => set('email', e.target.value)}
          />
        </div>
        <div>
          <label>Phone number</label>
          <input
            required
            value={f.phoneNumber}
            onChange={(e) => set('phoneNumber', e.target.value)}
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
          <label>Service area</label>
          <input
            required
            value={f.serviceArea}
            onChange={(e) => set('serviceArea', e.target.value)}
          />
        </div>
        <div>
          <label>Rating (0–5)</label>
          <input
            type="number"
            min={0}
            max={5}
            step={0.1}
            value={f.rating ?? 0}
            onChange={(e) => set('rating', Number(e.target.value))}
          />
        </div>
        <div>
          <label>Available</label>
          <select
            value={f.available ? 'yes' : 'no'}
            onChange={(e) => set('available', e.target.value === 'yes')}
          >
            <option value="yes">Available</option>
            <option value="no">Unavailable</option>
          </select>
        </div>
        <div className="full">
          <label>Opening hours</label>
          <input
            value={f.openingHours ?? ''}
            onChange={(e) => set('openingHours', e.target.value)}
            placeholder="Monday – Saturday   6:00AM – 11:00PM"
          />
        </div>
        <div className="full">
          <label>About</label>
          <textarea
            rows={3}
            value={f.about ?? ''}
            onChange={(e) => set('about', e.target.value)}
          />
        </div>
      </div>
      {error && <p className="error-text" style={{ marginTop: 12 }}>{error}</p>}
      <div className="form-actions">
        <button type="submit" className="primary" disabled={submitting}>
          {submitting ? 'Saving…' : initial ? 'Save changes' : 'Create technician'}
        </button>
        <button type="button" onClick={onCancel} disabled={submitting}>
          Cancel
        </button>
      </div>
    </form>
  );
}
