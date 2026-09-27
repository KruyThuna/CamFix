import { useState, type FormEvent } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api, errorMessage } from '../api/client';
import type { UserInfo } from '../api/types';
import { useAuth } from '../auth/AuthContext';

const blank = { firstName: '', lastName: '', email: '', phoneNumber: '', password: '' };

export function UsersPage() {
  const { user } = useAuth();
  const mainAdmin = user?.role.toUpperCase() === 'MAIN_ADMIN';
  const qc = useQueryClient();
  const [search, setSearch] = useState('');
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<UserInfo | null>(null);
  const [form, setForm] = useState(blank);
  const [error, setError] = useState<string | null>(null);
  const query = useQuery({ queryKey: ['managed-users'],
    queryFn: async () => (await api.get<UserInfo[]>('/api/admin/users')).data });
  const save = useMutation({
    mutationFn: async () => {
      if (editing) return api.put(`/api/admin/users/${editing.id}`, {
        firstName: form.firstName, lastName: form.lastName, phoneNumber: form.phoneNumber,
      });
      return api.post('/api/admin/users/admins', form);
    },
    onSuccess: () => { setCreating(false); setEditing(null); setForm(blank);
      qc.invalidateQueries({ queryKey: ['managed-users'] }); },
    onError: (e) => setError(errorMessage(e)),
  });
  const remove = useMutation({
    mutationFn: (id: number) => api.delete(`/api/admin/users/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['managed-users'] }),
    onError: (e) => setError(errorMessage(e)),
  });
  const submit = (e: FormEvent) => { e.preventDefault(); setError(null); save.mutate(); };
  const users = (query.data ?? []).filter(u =>
    `${u.firstName} ${u.lastName} ${u.email} ${u.phoneNumber} ${u.role}`.toLowerCase().includes(search.toLowerCase()));
  return <>
    <div className="page-head"><div><h1>Users</h1>
      <p className="sub">Manage customer and technician accounts.</p></div>
      {mainAdmin && <button className="primary" onClick={() => {
        setCreating(true); setEditing(null); setForm(blank); setError(null);
      }}>Create Admin</button>}
    </div>
    {error && <p className="error-text" role="alert">{error}</p>}
    {(creating || editing) && <form className="card pad stack" onSubmit={submit}>
      <h2>{editing ? 'Edit user' : 'Create Admin'}</h2>
      {!editing && <p className="muted">Admins can manage regular users, technicians and jobs. Only Main Admin can create or delete Admin accounts.</p>}
      {(['firstName', 'lastName', 'phoneNumber'] as const).map(key => <div key={key}>
        <label htmlFor={key}>{({ firstName: 'First name', lastName: 'Last name', phoneNumber: 'Phone number' })[key]}</label>
        <input id={key} required maxLength={key === 'phoneNumber' ? 100 : 50}
          value={form[key]} onChange={e => setForm({ ...form, [key]: e.target.value })} />
      </div>)}
      {!editing && <>
        <div><label htmlFor="new-email">Email</label><input id="new-email" type="email" required maxLength={100}
          value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} /></div>
        <div><label htmlFor="new-password">Password (at least 12 characters)</label>
          <input id="new-password" type="password" autoComplete="new-password" required minLength={12} maxLength={72}
            value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} /></div>
      </>}
      <div className="inline"><button className="primary" disabled={save.isPending}>
        {save.isPending ? 'Saving...' : 'Save'}</button>
        <button type="button" disabled={save.isPending} onClick={() => {
          setCreating(false); setEditing(null); setForm(blank); setError(null);
        }}>Cancel</button></div>
    </form>}
    <div className="toolbar"><div className="field grow"><label htmlFor="user-search">Search users</label>
      <input id="user-search" placeholder="Name, email, phone or role" value={search} onChange={e => setSearch(e.target.value)} /></div></div>
    {query.isLoading && <p>Loading users...</p>}
    {query.error && <p className="error-text">{errorMessage(query.error)} <button onClick={() => query.refetch()}>Retry</button></p>}
    <div className="card table-wrap"><table><thead><tr>
      <th>Name</th><th>Email</th><th>Phone</th><th>Role</th><th>Status</th><th>Actions</th>
    </tr></thead><tbody>{users.map(u => {
      const editable = u.id !== user?.id && u.role !== 'MAIN_ADMIN' && (mainAdmin || ['CUSTOMER', 'TECHNICIAN'].includes(u.role));
      return <tr key={u.id}><td>{u.firstName} {u.lastName}</td><td>{u.email}</td><td>{u.phoneNumber}</td>
        <td>{u.role.replace(/_/g, ' ')}</td><td>{u.status}</td><td>{editable ? <div className="inline">
          <button disabled={save.isPending || remove.isPending} onClick={() => {
            setEditing(u); setCreating(false); setForm({ ...blank, ...u }); setError(null);
          }}>Edit</button>
          <button className="danger" disabled={remove.isPending || save.isPending} onClick={() => {
            if (window.confirm(`Permanently delete ${u.firstName} ${u.lastName} (${u.email})? Accounts with linked records cannot be deleted.`)) {
              setError(null); remove.mutate(u.id);
            }
          }}>Delete</button></div> : <span className="muted">Protected</span>}</td></tr>;
    })}</tbody></table>
    {!query.isLoading && !query.error && users.length === 0 && <div className="empty">No users found.</div>}</div>
  </>;
}
