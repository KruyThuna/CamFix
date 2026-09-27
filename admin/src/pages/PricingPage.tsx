import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api, errorMessage } from '../api/client';

interface ServicePrice {
  categoryId: number;
  categoryName: string | null;
  startingPrice: number;
  description: string | null;
  benchFee: number | null;
  travelFee: number | null;
}

type Draft = { startingPrice: string; travelFee: string; benchFee: string };

const toDraft = (p: ServicePrice): Draft => ({
  startingPrice: String(p.startingPrice ?? ''),
  travelFee: p.travelFee == null ? '' : String(p.travelFee),
  benchFee: p.benchFee == null ? '' : String(p.benchFee),
});

// Empty input = clear the fee (null), so the customer app hides that line.
const toNumber = (v: string) => (v.trim() === '' ? null : Number(v));

export function PricingPage() {
  const qc = useQueryClient();
  const [drafts, setDrafts] = useState<Record<number, Draft>>({});
  const [error, setError] = useState<string | null>(null);
  const [savedId, setSavedId] = useState<number | null>(null);

  const query = useQuery({
    queryKey: ['service-prices'],
    queryFn: async () => (await api.get<ServicePrice[]>('/api/service-prices')).data,
  });

  const save = useMutation({
    mutationFn: async ({ id, draft }: { id: number; draft: Draft }) =>
      api.put(`/api/service-prices/category/${id}`, {
        startingPrice: toNumber(draft.startingPrice),
        travelFee: toNumber(draft.travelFee),
        benchFee: toNumber(draft.benchFee),
      }),
    onSuccess: (_, { id }) => {
      setSavedId(id);
      setDrafts((d) => {
        const next = { ...d };
        delete next[id];
        return next;
      });
      qc.invalidateQueries({ queryKey: ['service-prices'] });
    },
    onError: (e) => setError(errorMessage(e)),
  });

  const rows = [...(query.data ?? [])].sort((a, b) =>
    (a.categoryName ?? '').localeCompare(b.categoryName ?? ''),
  );

  const draftFor = (p: ServicePrice) => drafts[p.categoryId] ?? toDraft(p);
  const edit = (p: ServicePrice, key: keyof Draft, value: string) => {
    setSavedId(null);
    setDrafts((d) => ({ ...d, [p.categoryId]: { ...draftFor(p), [key]: value } }));
  };

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Pricing</h1>
          <p className="sub">
            What customers see before booking. Leave a fee blank to turn it off — the app hides
            any fee that isn't set.
          </p>
        </div>
      </div>
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
      <div className="card pad stack">
        <p className="muted">
          <b>Travel fee</b> is the standard home-visit travel charge — Self Drop bookings never pay
          it. <b>Bench fee</b> is the diagnostic fee for Self Drop, paid at drop-off; it's locked
          in when the customer books and becomes the inspection fee on the technician's quote.
        </p>
      </div>
      <div className="table-wrap card">
        <table>
          <thead>
            <tr>
              <th>Category</th>
              <th>Starting price ($)</th>
              <th>Travel fee ($)</th>
              <th>Self Drop bench fee ($)</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {query.isLoading && (
              <tr>
                <td colSpan={5} className="muted">
                  Loading…
                </td>
              </tr>
            )}
            {rows.map((p) => {
              const d = draftFor(p);
              const dirty = drafts[p.categoryId] !== undefined;
              return (
                <tr key={p.categoryId}>
                  <td>{p.categoryName ?? `#${p.categoryId}`}</td>
                  {(['startingPrice', 'travelFee', 'benchFee'] as const).map((key) => (
                    <td key={key}>
                      <input
                        type="number"
                        min={0}
                        step="0.01"
                        required={key === 'startingPrice'}
                        placeholder={key === 'startingPrice' ? '' : 'Not set'}
                        value={d[key]}
                        onChange={(e) => edit(p, key, e.target.value)}
                        aria-label={`${p.categoryName} ${key}`}
                      />
                    </td>
                  ))}
                  <td>
                    <button
                      className="primary"
                      disabled={!dirty || save.isPending || d.startingPrice.trim() === ''}
                      onClick={() => {
                        setError(null);
                        save.mutate({ id: p.categoryId, draft: d });
                      }}
                    >
                      {savedId === p.categoryId && !dirty ? 'Saved' : 'Save'}
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </>
  );
}
