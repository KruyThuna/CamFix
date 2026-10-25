export function fmtDate(iso: string | null | undefined): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function fmtRelative(iso: string | null | undefined): string {
  if (!iso) return 'never';
  const diffMs = Date.now() - new Date(iso).getTime();
  const min = Math.round(diffMs / 60000);
  if (min < 1) return 'just now';
  if (min < 60) return `${min} min ago`;
  const hr = Math.round(min / 60);
  if (hr < 24) return `${hr} h ago`;
  return `${Math.round(hr / 24)} d ago`;
}

export function isSyntheticEmail(email: string | null | undefined): boolean {
  if (!email || email.trim() === '') return true;
  return email.toLowerCase().endsWith('@phone.camfix.local');
}

export function fmtEmail(email: string | null | undefined): string {
  return isSyntheticEmail(email) ? 'N/A' : (email ?? 'N/A');
}
